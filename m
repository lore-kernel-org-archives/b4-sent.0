From: Frank Li <Frank.Li@nxp.com>
Date: Wed, 09 Jul 2025 17:02:20 -0400
Subject: [PATCH v20 8/9] selftests: pci_endpoint: Add doorbell test case
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250709-ep-msi-v20-8-43d56f9bd54a@nxp.com>
References: <20250709-ep-msi-v20-0-43d56f9bd54a@nxp.com>
In-Reply-To: <20250709-ep-msi-v20-0-43d56f9bd54a@nxp.com>
To: Kishon Vijay Abraham I <kishon@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Anup Patel <apatel@ventanamicro.com>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Arnd Bergmann <arnd@arndb.de>, 
 Shuah Khan <shuah@kernel.org>, Richard Zhu <hongxing.zhu@nxp.com>, 
 Lucas Stach <l.stach@pengutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, Rob Herring <robh@kernel.org>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>
Cc: Niklas Cassel <cassel@kernel.org>, dlemoal@kernel.org, jdmason@kudzu.us, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-pci@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 imx@lists.linux.dev, devicetree@vger.kernel.org, 
 Niklas Cassel <cassel@kernel.org>, Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752094968; l=2413;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=DF/gzaI0MKU27j4SEtbbhXRg9y3PEJqjIqoano8U714=;
 b=a6gnp8u8O795/R0p6ZjiJhEZA5Qk09eT8q9NFI2+fCPfzc1F/KrDN6Ov4sdeNa2sfEKPQH5Wz
 sUKXPYdiqrcCtzdhAnea1XzTNhJ6/G+CWFkrildTnmpbPr/23Dp9+MG
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add doorbell test case.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
change in v20
- update document

change from v14 to v16
- Add set IRQ type

change from v13 to v14
- merge to selftests framework
---
 Documentation/PCI/endpoint/pci-test-howto.rst      | 14 +++++++++++
 .../selftests/pci_endpoint/pci_endpoint_test.c     | 28 ++++++++++++++++++++++
 2 files changed, 42 insertions(+)

diff --git a/Documentation/PCI/endpoint/pci-test-howto.rst b/Documentation/PCI/endpoint/pci-test-howto.rst
index aafc17ef3fd31f6ada38c82c8df133b87f7a1ae1..0cee35dcb29cc938823de53ef6e1a1cd81d49d52 100644
--- a/Documentation/PCI/endpoint/pci-test-howto.rst
+++ b/Documentation/PCI/endpoint/pci-test-howto.rst
@@ -203,3 +203,17 @@ controllers, it is advisable to skip this testcase using this
 command::
 
 	# pci_endpoint_test -f pci_ep_bar -f pci_ep_basic -v memcpy -T COPY_TEST -v dma
+
+Kselftest EP Doorbell
+~~~~~~~~~~~~~~~~~~~~~
+
+If EP side have MSI controller, run below command to test doorbell function.
+
+	# pci_endpoint_test -f pcie_ep_doorbell
+
+	# Starting 1 tests from 1 test cases.
+	#  RUN           pcie_ep_doorbell.DOORBELL_TEST ...
+	#            OK  pcie_ep_doorbell.DOORBELL_TEST
+	ok 1 pcie_ep_doorbell.DOORBELL_TEST
+	# PASSED: 1 / 1 tests passed.
+	# Totals: pass:1 fail:0 xfail:0 xpass:0 skip:0 error:0
diff --git a/tools/testing/selftests/pci_endpoint/pci_endpoint_test.c b/tools/testing/selftests/pci_endpoint/pci_endpoint_test.c
index ac26481d29d9dce5d07de563048850c55c58c22d..da0db0e7c9693f11b4975ca0e6830174229983ba 100644
--- a/tools/testing/selftests/pci_endpoint/pci_endpoint_test.c
+++ b/tools/testing/selftests/pci_endpoint/pci_endpoint_test.c
@@ -229,4 +229,32 @@ TEST_F(pci_ep_data_transfer, COPY_TEST)
 					 test_size[i]);
 	}
 }
+
+FIXTURE(pcie_ep_doorbell)
+{
+	int fd;
+};
+
+FIXTURE_SETUP(pcie_ep_doorbell)
+{
+	self->fd = open(test_device, O_RDWR);
+
+	ASSERT_NE(-1, self->fd) TH_LOG("Can't open PCI Endpoint Test device");
+};
+
+FIXTURE_TEARDOWN(pcie_ep_doorbell)
+{
+	close(self->fd);
+};
+
+TEST_F(pcie_ep_doorbell, DOORBELL_TEST)
+{
+	int ret;
+
+	pci_ep_ioctl(PCITEST_SET_IRQTYPE, PCITEST_IRQ_TYPE_AUTO);
+	ASSERT_EQ(0, ret) TH_LOG("Can't set AUTO IRQ type");
+
+	pci_ep_ioctl(PCITEST_DOORBELL, 0);
+	EXPECT_FALSE(ret) TH_LOG("Test failed for Doorbell\n");
+}
 TEST_HARNESS_MAIN

-- 
2.34.1

