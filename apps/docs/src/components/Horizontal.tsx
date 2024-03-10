import type { ReactNode, FC } from "react";

type HorizontalProps = {
  children: ReactNode;
};

export const Horizontal: FC<HorizontalProps> = ({ children }) => {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "row",
        alignItems: "center",
        justifyContent: "space-between",
        width: "100%",
      }}
    >
      {children}
    </div>
  );
};
