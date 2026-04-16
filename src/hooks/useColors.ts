import { useState, useEffect } from 'react';
import {
  getColors, setColor, resetColors, subscribeColors,
} from '../stores/colorStore';

export function useColors() {
  const [colors, setColors] = useState(getColors);

  useEffect(() => {
    setColors(getColors());
    return subscribeColors(() => setColors(getColors()));
  }, []);

  return { colors, setColor, resetColors };
}
