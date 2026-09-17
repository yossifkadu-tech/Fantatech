"""
SecretStore — encrypts sensitive values (Tuya local_key, cloud API secrets, etc.)
at rest using Fernet (AES-128-CBC + HMAC) from the `cryptography` package.

Why `cryptography`: it's already present in this environment (pulled in
transitively) and is the standard, actively-maintained choice for exactly
this — authenticated symmetric encryption with no custom crypto to get
wrong. Fernet keeps encrypt/decrypt to two calls, which is all this needs.

Key management: a per-installation key file (hub/.secret.key), generated on
first run and chmod'd 0600 where the OS supports it. It never leaves the
hub machine — matches FantaTech's local-first, per-installation model (the
hub is not part of the shared cloud footprint, see the `cloud` skill), so
there's no multi-machine key-sync problem to solve. Never commit this file;
it's in .gitignore.

Encrypted values are stored with an "enc:" prefix so decrypt_field() can
tell them apart from the plaintext secrets already sitting in existing
installs' databases — those keep working (read as plaintext) until the next
write re-encrypts them. See routers/tuya.py: migrate_plaintext_secrets().
"""
import os
from cryptography.fernet import Fernet, InvalidToken

_KEY_PATH = os.path.join(os.path.dirname(__file__), ".secret.key")
_PREFIX = "enc:"

_fernet: Fernet | None = None


def _load_or_create_key() -> bytes:
    if os.path.exists(_KEY_PATH):
        with open(_KEY_PATH, "rb") as f:
            return f.read().strip()
    key = Fernet.generate_key()
    with open(_KEY_PATH, "wb") as f:
        f.write(key)
    try:
        os.chmod(_KEY_PATH, 0o600)
    except OSError:
        pass  # best-effort — not all filesystems (e.g. Windows) honor this
    return key


def _get_fernet() -> Fernet:
    global _fernet
    if _fernet is None:
        _fernet = Fernet(_load_or_create_key())
    return _fernet


def encrypt_field(value: str) -> str:
    """Encrypt a secret for storage. Idempotent — an already-encrypted value
    (already carrying the "enc:" prefix) passes through unchanged, so callers
    can encrypt on every write without double-wrapping."""
    if not value:
        return value
    if value.startswith(_PREFIX):
        return value
    token = _get_fernet().encrypt(value.encode("utf-8")).decode("utf-8")
    return _PREFIX + token


def decrypt_field(value: str) -> str:
    """Decrypt a stored secret. A legacy plaintext value (no "enc:" prefix,
    from before this module existed) passes through unchanged so existing
    installs keep working without a hard migration step."""
    if not value or not value.startswith(_PREFIX):
        return value
    token = value[len(_PREFIX):]
    try:
        return _get_fernet().decrypt(token.encode("utf-8")).decode("utf-8")
    except InvalidToken:
        # Corrupted value or a key file from a different install — fail
        # closed (treat as absent) rather than surfacing garbage bytes.
        return ""


def mask(value: str) -> str:
    """For logs/diagnostics/API responses — never surface a real secret,
    encrypted or not."""
    return "********" if value else ""
