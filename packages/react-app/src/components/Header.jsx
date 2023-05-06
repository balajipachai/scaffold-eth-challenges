import { PageHeader } from "antd";
import React from "react";

// displays a page header
// TODO Change the href to etherscan code
export default function Header() {
  return (
    <a
      href="https://sepolia.etherscan.io/address/0x5c1ab06121367fde55b8ce1a616c3b520fa67dc9#code"
      target="_blank"
      rel="noopener noreferrer"
    >
      <PageHeader
        title="Dice Game"
        subTitle="SpeedRun Ethereum: Challenge - 3: Dice Game"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
