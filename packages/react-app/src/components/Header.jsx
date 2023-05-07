import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a
      href="https://sepolia.etherscan.io/address/0x95bed224ffc17135d39502b0d437bf72b3594fba#code"
      target="_blank"
      rel="noopener noreferrer"
    >
      <PageHeader
        title="SpeedRun Ethereum: Build a DEX Challenge"
        subTitle="🚩 Challenge 4: Minimum Viable Exchange"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
