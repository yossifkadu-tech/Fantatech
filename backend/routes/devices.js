const { Router } = require("express");
const { CLUSTERS } = require("../matter/client");

// matterClient is injected by server.js via req.app.locals
const router = Router();

// GET /devices — list all commissioned Matter nodes
router.get("/", async (req, res) => {
  try {
    const nodes = await req.app.locals.matter.getNodes();
    res.json(nodes);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

// POST /devices/:nodeId/command
// Body: { endpoint, cluster, command, payload }
router.post("/:nodeId/command", async (req, res) => {
  const nodeId   = parseInt(req.params.nodeId, 10);
  const { endpoint = 1, cluster, command, payload = {} } = req.body;

  try {
    const result = await req.app.locals.matter.sendCommand(
      nodeId, endpoint, cluster, command, payload
    );
    res.json({ ok: true, result });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

// ── Convenience endpoints ────────────────────────────────────

// POST /devices/:nodeId/light  { on: true|false }
router.post("/:nodeId/light", async (req, res) => {
  const nodeId = parseInt(req.params.nodeId, 10);
  const { on }  = req.body;
  try {
    await req.app.locals.matter.setLight(nodeId, !!on);
    res.json({ ok: true });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

// POST /devices/:nodeId/lock  { lock: true|false }
router.post("/:nodeId/lock", async (req, res) => {
  const nodeId  = parseInt(req.params.nodeId, 10);
  const { lock } = req.body;
  try {
    await req.app.locals.matter.setLock(nodeId, !!lock);
    res.json({ ok: true });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

// POST /devices/:nodeId/blinds  { open: true|false }
router.post("/:nodeId/blinds", async (req, res) => {
  const nodeId  = parseInt(req.params.nodeId, 10);
  const { open } = req.body;
  try {
    await req.app.locals.matter.setBlinds(nodeId, !!open);
    res.json({ ok: true });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

// POST /devices/:nodeId/thermostat  { temp: 22 }
router.post("/:nodeId/thermostat", async (req, res) => {
  const nodeId = parseInt(req.params.nodeId, 10);
  const { temp } = req.body;
  try {
    await req.app.locals.matter.setThermostat(nodeId, temp);
    res.json({ ok: true });
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

module.exports = router;
