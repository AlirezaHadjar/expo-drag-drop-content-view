import type { ReactNode, FC } from "react";

type RowContainerProps = {
  children: ReactNode;
};

export const RowContainer: FC<RowContainerProps> = ({ children }) => {
  return <div className="row-container">{children}</div>;
};
