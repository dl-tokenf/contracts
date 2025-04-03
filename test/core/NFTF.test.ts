import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ComplianceFalseHooksMock, ComplianceRevertHooksMock, FacetMock, NFTFMock } from "@ethers-v6";
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

describe("NFT F", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;
  let bob: SignerWithAddress;
  let alice: SignerWithAddress;

  let nftF: NFTFMock;

  const tokenId = 1;

  before("setup", async () => {
    [owner, agent, bob, alice] = await ethers.getSigners();

    const NFTFMock = await ethers.getContractFactory("NFTFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");

    nftF = await NFTFMock.deploy();
    const rCompliance = await RegulatoryComplianceMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceDirect_init");

    await nftF.__NFTFMock_init("NftF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    await nftF.grantRole(MINT_ROLE, agent);
    await nftF.grantRole(BURN_ROLE, agent);
    await nftF.grantRole(FORCED_TRANSFER_ROLE, agent);
    await nftF.grantRole(RECOVERY_ROLE, agent);
    await nftF.grantRole(DIAMOND_CUT_ROLE, agent);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(nftF.__NFTFMock_init("NftF", "TF", ZERO_ADDR, ZERO_ADDR, "0x", "0x")).to.be.revertedWithCustomError(
        nftF,
        "InvalidInitialization",
      );
    });

    it("should initialize only by top level contract", async () => {
      await expect(nftF.__NFTFDirect_init()).to.be.revertedWithCustomError(nftF, "NotInitializing");
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await nftF.name()).to.eq("NftF");
      expect(await nftF.symbol()).to.eq("TF");
      expect(await nftF.DEFAULT_ADMIN_ROLE(), ADMIN_ROLE);
      expect(await nftF.AGENT_ROLE(), AGENT_ROLE);
      expect(await nftF.defaultMintRole(), AGENT_ROLE);
      expect(await nftF.defaultBurnRole(), AGENT_ROLE);
      expect(await nftF.defaultForcedTransferRole(), AGENT_ROLE);
      expect(await nftF.defaultRecoveryRole(), AGENT_ROLE);
      expect(await nftF.defaultDiamondCutRole(), AGENT_ROLE);
      expect(await nftF.hasRole(await nftF.DEFAULT_ADMIN_ROLE(), owner)).to.be.true;
      expect(await nftF.hasRole(await nftF.AGENT_ROLE(), owner)).to.be.true;
    });
  });

  describe("transfer", () => {
    it("should transfer if all conditions are met", async () => {
      await nftF.connect(agent).mint(bob, tokenId);

      await expect(nftF.connect(bob).transfer(alice, tokenId)).to.changeTokenBalances(nftF, [bob, alice], [-1, 1]);

      expect(await nftF.ownerOf(tokenId)).to.eq(alice);
    });
  });

  describe("transferFrom", () => {
    it("should transfer if all conditions are met", async () => {
      await nftF.connect(agent).mint(bob, tokenId);

      await nftF.connect(bob).approve(alice, tokenId);

      await expect(nftF.connect(alice).transferFrom(bob, alice, tokenId)).to.changeTokenBalances(
        nftF,
        [bob, alice],
        [-1, 1],
      );

      expect(await nftF.ownerOf(tokenId)).to.eq(alice);
    });
  });

  describe("mint", () => {
    it("should not mint if no role", async () => {
      await nftF.revokeRole(MINT_ROLE, agent);

      await expect(nftF.connect(agent).mint(bob, tokenId))
        .to.be.revertedWithCustomError(nftF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, MINT_ROLE);
    });

    it("should mint if all conditions are met", async () => {
      await expect(nftF.connect(agent).mint(bob, tokenId)).to.changeTokenBalance(nftF, bob, 1);

      expect(await nftF.ownerOf(tokenId)).to.eq(bob);
    });
  });

  describe("burn", () => {
    it("should not burn if no role", async () => {
      await nftF.revokeRole(BURN_ROLE, agent);

      await expect(nftF.connect(agent).burn(tokenId))
        .to.be.revertedWithCustomError(nftF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, BURN_ROLE);
    });

    it("should burn if all conditions are met", async () => {
      await nftF.connect(agent).mint(bob, tokenId);

      await expect(nftF.connect(agent).burn(tokenId)).to.changeTokenBalance(nftF, bob, -1);
    });
  });

  describe("forcedTransfer", () => {
    it("should not forced transfer if no role", async () => {
      await nftF.revokeRole(FORCED_TRANSFER_ROLE, agent);

      await expect(nftF.connect(agent).forcedTransfer(bob, alice, tokenId))
        .to.be.revertedWithCustomError(nftF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, FORCED_TRANSFER_ROLE);
    });

    it("should forced transfer if all conditions are met", async () => {
      await nftF.connect(agent).mint(bob, tokenId);

      await expect(nftF.connect(agent).forcedTransfer(bob, alice, tokenId)).to.changeTokenBalances(
        nftF,
        [bob, alice],
        [-1, 1],
      );
    });
  });

  describe("recovery", () => {
    it("should not recover if no role", async () => {
      await nftF.revokeRole(RECOVERY_ROLE, agent);

      await expect(nftF.connect(agent).recovery(bob, alice))
        .to.be.revertedWithCustomError(nftF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, RECOVERY_ROLE);
    });

    it("should recover if all conditions are met", async () => {
      const bobTokens = [0, 1, 3];

      await nftF.connect(agent).mint(bob, bobTokens[0]);
      await nftF.connect(agent).mint(bob, bobTokens[1]);
      await nftF.connect(agent).mint(bob, bobTokens[2]);

      await expect(nftF.connect(agent).recovery(bob, alice)).to.changeTokenBalances(nftF, [bob, alice], [-3, 3]);

      for (const tokenId of bobTokens) {
        expect(await nftF.ownerOf(tokenId)).to.eq(alice.address);
      }
    });
  });

  describe("supportsInterface", () => {
    it("should support following interfaces: IAccessControl, IERC721Enumerable", async () => {
      // IERC721Enumerable -- 0x780e9d63
      expect(await nftF.supportsInterface("0x780e9d63")).to.be.true;

      // ERC165 -- 0x01ffc9a7
      expect(await nftF.supportsInterface("0x01ffc9a7")).to.be.true;

      // IAccessControl -- 0x7965db0b
      expect(await nftF.supportsInterface("0x7965db0b")).to.be.true;
    });
  });

  describe("diamondCut", () => {
    let facet: FacetMock;
    let facetProxy: FacetMock;

    beforeEach(async () => {
      const FacetMock = await ethers.getContractFactory("FacetMock");

      facet = await FacetMock.deploy();
      facetProxy = FacetMock.attach(nftF) as FacetMock;
    });

    it("should not diamond cut if no role", async () => {
      await nftF.revokeRole(DIAMOND_CUT_ROLE, agent);

      const facets = [
        {
          facetAddress: facet,
          action: FacetAction.Add,
          functionSelectors: [facet.interface.getFunction("mockFunction").selector],
        },
      ];

      await expect(nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets))
        .to.be.revertedWithCustomError(nftF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, DIAMOND_CUT_ROLE);

      await expect(nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[],address,bytes)"](facets, ZERO_ADDR, "0x"))
        .to.be.revertedWithCustomError(nftF, "AccessControlUnauthorizedAccount")
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
        .to.be.revertedWithCustomError(nftF, "SelectorNotRegistered")
        .withArgs(selector);

      await nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

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
        .to.be.revertedWithCustomError(nftF, "SelectorNotRegistered")
        .withArgs(selector);

      await nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[],address,bytes)"](facets, ZERO_ADDR, "0x");

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
      await expect(nftF.connect(agent).mint(alice, tokenId)).to.not.be.reverted;
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

        await nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(nftF.connect(agent).mint(alice, tokenId)).to.be.revertedWithCustomError(nftF, "NotKYCed");
      });

      it("should revert if revert hook", async () => {
        const facets = [
          {
            facetAddress: complianceRevertHooks,
            action: FacetAction.Replace,
            functionSelectors: [complianceRevertHooks.interface.getFunction("isKYCed").selector],
          },
        ];

        await nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(nftF.connect(agent).mint(alice, tokenId)).to.be.revertedWithCustomError(nftF, "IsKYCedReverted");
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

        await nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(nftF.connect(agent).mint(alice, tokenId)).to.be.revertedWithCustomError(nftF, "CannotTransfer");
      });

      it("should revert if revert hook", async () => {
        const facets = [
          {
            facetAddress: complianceRevertHooks,
            action: FacetAction.Replace,
            functionSelectors: [complianceRevertHooks.interface.getFunction("canTransfer").selector],
          },
        ];

        await nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(nftF.connect(agent).mint(alice, tokenId)).to.be.revertedWithCustomError(
          nftF,
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

        await nftF.connect(agent)["diamondCut((address,uint8,bytes4[])[])"](facets);

        await expect(nftF.connect(agent).mint(alice, tokenId)).to.be.revertedWithCustomError(
          nftF,
          "TransferredReverted",
        );
      });
    });
  });
});
