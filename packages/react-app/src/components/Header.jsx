import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a
      href="https://sepolia.etherscan.io/address/0x1E8f8D12c59Af2570a74C2B0B3D349Ce2691A8B4#code"
      target="_blank"
      rel="noopener noreferrer"
    >
      <PageHeader
        title="Challenge 6 - A State Channel Application"
        subTitle="🧑‍🤝‍🧑 State channels really excel as a scaling solution in cases where a fixed set of participants want to exchange value-for-service at high frequency."
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
