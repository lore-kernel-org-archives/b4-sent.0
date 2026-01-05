From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 05 Jan 2026 19:25:47 +0530
Subject: [PATCH v4 7/8] PCI: Drop the assert_perst() callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-pci-pwrctrl-rework-v4-7-6d41a7a49789@oss.qualcomm.com>
References: <20260105-pci-pwrctrl-rework-v4-0-6d41a7a49789@oss.qualcomm.com>
In-Reply-To: <20260105-pci-pwrctrl-rework-v4-0-6d41a7a49789@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen-Yu Tsai <wens@kernel.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Alex Elder <elder@riscstar.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=825;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=mldIwFB+pfS0iHVRsCTaT7tjmBqPl6lu5qJtujWhd3Q=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpW8LyVBYfz3xhbl7+el0cIb91U5kt94P74OLiw
 o1Yhqe8zF6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVvC8gAKCRBVnxHm/pHO
 9epHB/0W4m7lYWGPNArq3VBa1EUKqIQ0qyhqXo2i+3axGgso/fDwuAtXcwiy7qPUJXVhrbrx1OG
 FeZu7WPbVDvZCBcnW1aASyZCX0F7vG25AihVgarQSXeJPXJTNmXwhu35ITKMVLQxGS6540DFwO4
 muAf/va91gx7t3s0jESMW6U/nqnu2JqpNNyC1SFS07Q+1NtTgHoflODnZY6XI435G6lUQUw/BI0
 wWMJvKAykAEll5V/cmKbgbaO/IpaK7wNUmftRGhjtkcjqqO2TsWl+L2FF9SCMw9UnfvlMIiGvAl
 AD0cHLWjQz05llQyOu+yGJVFH0ZbxhjBwiJs+ARa6fME8pWN
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now since all .assert_callback() implementations have been removed from the
controller drivers, drop the .assert_callback callback from pci.h.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 include/linux/pci.h | 1 -
 1 file changed, 1 deletion(-)

diff --git a/include/linux/pci.h b/include/linux/pci.h
index 864775651c6f..3eb8fd975ad9 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -854,7 +854,6 @@ struct pci_ops {
 	void __iomem *(*map_bus)(struct pci_bus *bus, unsigned int devfn, int where);
 	int (*read)(struct pci_bus *bus, unsigned int devfn, int where, int size, u32 *val);
 	int (*write)(struct pci_bus *bus, unsigned int devfn, int where, int size, u32 val);
-	int (*assert_perst)(struct pci_bus *bus, bool assert);
 };
 
 /*

-- 
2.48.1

