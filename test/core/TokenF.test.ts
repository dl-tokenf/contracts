import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { wei } from "@/scripts/utils/utils";
import { Reverter } from "@/test/helpers/reverter";
import { ComplianceFalseHooksMock, ComplianceRevertHooksMock, FacetMock, TokenFMock } from "@ethers-v6";
import { ZERO_ADDR } from "@/scripts/utils/constants";
import {
  ADMIN_ROLE,
  AGENT_ROLE,
  BURN_ROLE,
  DIAMOND_CUT_ROLE,
  FacetAction,
  FORCED_TRANSFER_ROLE,
  MINT_ROLE,
  RECOVERY_ROLE,
} from "@/test/helpers/utils";

describe("TokenF", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;
  let bob: SignerWithAddress;
  let alice: SignerWithAddress;

  let tokenF: TokenFMock;

  before("setup", async () => {
    [owner, agent, bob, alice] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");

    tokenF = await TokenFMock.deploy();
    const rCompliance = await RegulatoryComplianceMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceDirect_init");

    await tokenF.__TokenFMock_init("TokenF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    await tokenF.grantRole(MINT_ROLE, agent);
    await tokenF.grantRole(BURN_ROLE, agent);
    await tokenF.grantRole(FORCED_TRANSFER_ROLE, agent);
    await tokenF.grantRole(RECOVERY_ROLE, agent);
    await tokenF.grantRole(DIAMOND_CUT_ROLE, agent);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(
        tokenF.__TokenFMock_init("TokenF", "TF", ZERO_ADDR, ZERO_ADDR, "0x", "0x"),
      ).to.be.revertedWithCustomError(tokenF, "InvalidInitialization");
    });

    it("should initialize only by top level contract", async () => {
      await expect(tokenF.__TokenFDirect_init()).to.be.revertedWithCustomError(tokenF, "NotInitializing");
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await tokenF.name()).to.eq("TokenF");
      expect(await tokenF.symbol()).to.eq("TF");
      expect(await tokenF.DEFAULT_ADMIN_ROLE(), ADMIN_ROLE);
      expect(await tokenF.AGENT_ROLE(), AGENT_ROLE);
      expect(await tokenF.defaultMintRole(), AGENT_ROLE);
      expect(await tokenF.defaultBurnRole(), AGENT_ROLE);
      expect(await tokenF.defaultForcedTransferRole(), AGENT_ROLE);
      expect(await tokenF.defaultRecoveryRole(), AGENT_ROLE);
      expect(await tokenF.defaultDiamondCutRole(), AGENT_ROLE);
      expect(await tokenF.hasRole(await tokenF.DEFAULT_ADMIN_ROLE(), owner)).to.be.true;
      expect(await tokenF.hasRole(await tokenF.AGENT_ROLE(), owner)).to.be.true;
    });
  });

  describe("transfer", () => {
    it("should transfer if all conditions are met", async () => {
      await tokenF.connect(agent).mint(bob, wei("1"));

      await expect(tokenF.connect(bob).transfer(alice, wei("1"))).to.changeTokenBalances(
        tokenF,
        [bob, alice],
        [-wei("1"), wei("1")],
      );
    });
  });

  describe("transferFrom", () => {
    it("should transfer if all conditions are met", async () => {
      await tokenF.connect(agent).mint(bob, wei("1"));

      await tokenF.connect(bob).approve(alice, wei("1"));

      await expect(tokenF.connect(alice).transferFrom(bob, alice, wei("1"))).to.changeTokenBalances(
        tokenF,
        [bob, alice],
        [-wei("1"), wei("1")],
      );
    });
  });

  describe("mint", () => {
    it("should not mint if no role", async () => {
      await tokenF.revokeRole(MINT_ROLE, agent);

      await expect(tokenF.connect(agent).mint(bob, wei("1")))
        .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, MINT_ROLE);
    });

    it("should mint if all conditions are met", async () => {
      await expect(tokenF.connect(agent).mint(bob, wei("1"))).to.changeTokenBalance(tokenF, bob, wei("1"));
    });
  });

  describe("burn", () => {
    it("should not burn if no role", async () => {
      await tokenF.revokeRole(BURN_ROLE, agent);

      await expect(tokenF.connect(agent).burn(bob, wei("1")))
        .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, BURN_ROLE);
    });

    it("should mint if all conditions are met", async () => {
      await tokenF.connect(agent).mint(bob, wei("1"));

      await expect(tokenF.connect(agent).burn(bob, wei("1"))).to.changeTokenBalance(tokenF, bob, -wei("1"));
    });
  });

  describe("forcedTransfer", () => {
    it("should not forced transfer if no role", async () => {
      await tokenF.revokeRole(FORCED_TRANSFER_ROLE, agent);

      await expect(tokenF.connect(agent).forcedTransfer(bob, alice, wei("1")))
        .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, FORCED_TRANSFER_ROLE);
    });

    it("should forced transfer if all conditions are met", async () => {
      await tokenF.connect(agent).mint(bob, wei("1"));

      await expect(tokenF.connect(agent).forcedTransfer(bob, alice, wei("1"))).to.changeTokenBalances(
        tokenF,
        [bob, alice],
        [-wei("1"), wei("1")],
      );
    });
  });

  describe("recovery", () => {
    it("should not recover if no role", async () => {
      await tokenF.revokeRole(RECOVERY_ROLE, agent);

      await expect(tokenF.connect(agent).recovery(bob, alice))
        .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, RECOVERY_ROLE);
    });

    it("should recover if all conditions are met", async () => {
      await tokenF.connect(agent).mint(bob, wei("1"));

      await expect(tokenF.connect(agent).recovery(bob, alice)).to.changeTokenBalances(
        tokenF,
        [bob, alice],
        [-wei("1"), wei("1")],
      );
    });
  });

  describe("diamondCut", () => {
    let facet: FacetMock;
    let facetProxy: FacetMock;

    beforeEach(async () => {
      const FacetMock = await ethers.getContractFactory("FacetMock");

      facet = await FacetMock.deploy();
      facetProxy = FacetMock.attach(tokenF) as FacetMock;
    });

    it("should not diamond cut if no role", async () => {
      await tokenF.revokeRole(DIAMOND_CUT_ROLE, agent);

      const facets = [
        {
          facetAddress: facet,
          action: FacetAction.Add,
          functionSelectors: [facet.interface.getFunction("mockFunction").selector],
        },
      ];

      await expect(tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets))
        .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, DIAMOND_CUT_ROLE);

      await expect(
        tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[],address,bytes)"](facets, ZERO_ADDR, "0x"),
      )
        .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, DIAMOND_CUT_ROLE);
    });

    it("should diamond cut if all conditions are met", async () => {
      const facets = [
        {
          facetAddress: facet,
          action: FacetAction.Add,
          functionSelectors: [facet.interface.getFunction("mockFunction").selector],
        },
      ];

      const encodedFunc = new TextEncoder().encode("mockFunction()");
      const selector = ethers.keccak256(encodedFunc).slice(0, 10);

      await expect(facetProxy.mockFunction())
        .to.be.revertedWithCustomError(tokenF, "SelectorNotRegistered")
        .withArgs(selector);

      await tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

      expect(await facetProxy.mockFunction()).to.be.true;
    });

    it("should diamond cut if all conditions are met x2", async () => {
      const facets = [
        {
          facetAddress: facet,
          action: FacetAction.Add,
          functionSelectors: [facet.interface.getFunction("mockFunction").selector],
        },
      ];

      const encodedFunc = new TextEncoder().encode("mockFunction()");
      const selector = ethers.keccak256(encodedFunc).slice(0, 10);

      await expect(facetProxy.mockFunction())
        .to.be.revertedWithCustomError(tokenF, "SelectorNotRegistered")
        .withArgs(selector);

      await tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[],address,bytes)"](facets, ZERO_ADDR, "0x");

      expect(await facetProxy.mockFunction()).to.be.true;
    });
  });

  describe("hooks", () => {
    let complianceFalseHooks: ComplianceFalseHooksMock;
    let complianceRevertHooks: ComplianceRevertHooksMock;

    beforeEach(async () => {
      const ComplianceFalseHooksMock = await ethers.getContractFactory("ComplianceFalseHooksMock");
      const ComplianceRevertHooksMock = await ethers.getContractFactory("ComplianceRevertHooksMock");

      complianceFalseHooks = await ComplianceFalseHooksMock.deploy();
      complianceRevertHooks = await ComplianceRevertHooksMock.deploy();
    });

    it("should not revert if all conditions are met", async () => {
      await expect(tokenF.connect(agent).mint(alice, wei("1"))).to.not.be.reverted;
    });

    describe("isKYCed", () => {
      it("should revert if false hook", async () => {
        const facets = [
          {
            facetAddress: complianceFalseHooks,
            action: FacetAction.Replace,
            functionSelectors: [complianceFalseHooks.interface.getFunction("isKYCed").selector],
          },
        ];

        await tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(tokenF.connect(agent).mint(alice, wei("1"))).to.be.revertedWithCustomError(tokenF, "NotKYCed");
      });

      it("should revert if revert hook", async () => {
        const facets = [
          {
            facetAddress: complianceRevertHooks,
            action: FacetAction.Replace,
            functionSelectors: [complianceRevertHooks.interface.getFunction("isKYCed").selector],
          },
        ];

        await tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(tokenF.connect(agent).mint(alice, wei("1"))).to.be.revertedWithCustomError(
          tokenF,
          "IsKYCedReverted",
        );
      });
    });

    describe("canTransfer", () => {
      it("should revert if false hook", async () => {
        const facets = [
          {
            facetAddress: complianceFalseHooks,
            action: FacetAction.Replace,
            functionSelectors: [complianceFalseHooks.interface.getFunction("canTransfer").selector],
          },
        ];

        await tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(tokenF.connect(agent).mint(alice, wei("1"))).to.be.revertedWithCustomError(
          tokenF,
          "CannotTransfer",
        );
      });

      it("should revert if revert hook", async () => {
        const facets = [
          {
            facetAddress: complianceRevertHooks,
            action: FacetAction.Replace,
            functionSelectors: [complianceRevertHooks.interface.getFunction("canTransfer").selector],
          },
        ];

        await tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(tokenF.connect(agent).mint(alice, wei("1"))).to.be.revertedWithCustomError(
          tokenF,
          "CanTransferReverted",
        );
      });
    });

    describe("transferred", () => {
      it("should revert if revert hook", async () => {
        const facets = [
          {
            facetAddress: complianceRevertHooks,
            action: FacetAction.Replace,
            functionSelectors: [complianceRevertHooks.interface.getFunction("transferred").selector],
          },
        ];

        await tokenF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(tokenF.connect(agent).mint(alice, wei("1"))).to.be.revertedWithCustomError(
          tokenF,
          "TransferredReverted",
        );
      });
    });
  });
});
