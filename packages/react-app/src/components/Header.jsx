import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a
      href="https://sepolia.etherscan.io/address/0x6c2856BA45057f3E28901658D31aCf127b3f38a0#code"
      target="_blank"
      rel="noopener noreferrer"
    >
      <PageHeader
        title="Stake ETV"
        subTitle="Stake ETV to earn rETV (ETV Reward tokens)"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
