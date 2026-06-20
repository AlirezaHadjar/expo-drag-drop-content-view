import { useCallback, useEffect, useRef, useState } from "react";

import { Assets, DropAsset } from "./types";

export function useDropAssets() {
  const [assets, setAssets] = useState<DropAsset[]>([]);
  const releasers = useRef<Array<() => void>>([]);

  const onDrop = useCallback(({ assets: incoming }: Assets) => {
    incoming.forEach((a) => { if (a.release) releasers.current.push(a.release); });
    setAssets((prev) => [...prev, ...incoming]);
  }, []);

  const clear = useCallback(() => {
    releasers.current.forEach((r) => r());
    releasers.current = [];
    setAssets([]);
  }, []);

  useEffect(() => () => { releasers.current.forEach((r) => r()); }, []);

  return { assets, onDrop, clear };
}
