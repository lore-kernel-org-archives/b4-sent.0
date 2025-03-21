From: David Heidelberg <david@ixit.cz>
Date: Fri, 21 Mar 2025 21:48:47 +0100
Subject: [PATCH v3 5/7] x86/Kconfig: Document CONFIG_PCI_MMCONFIG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250321-x86_x2apic-v3-5-b0cbaa6fa338@ixit.cz>
References: <20250321-x86_x2apic-v3-0-b0cbaa6fa338@ixit.cz>
In-Reply-To: <20250321-x86_x2apic-v3-0-b0cbaa6fa338@ixit.cz>
To: Thomas Gleixner <tglx@linutronix.de>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>, 
 Kees Cook <kees@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: linux-kernel@vger.kernel.org, Ingo Molnar <mingo@kernel.org>, 
 linux-iio@vger.kernel.org, 
 =?utf-8?q?Mateusz_Jo=C5=84czyk?= <mat.jonczyk@o2.pl>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1354; i=david@ixit.cz;
 h=from:subject:message-id; bh=Wk/lNByjM8U8pBa5Ev4LNdWk6Mu/MLaTMuM+X8ijgiU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn3dCur5z5xbIM6Vj2mqrfW1IC8Kk112jMSEJlL
 9REVC+he/GJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ93QrgAKCRBgAj/E00kg
 ckQDD/0cjn/rv15TNepea/LN5OSmUsvz1KkEO9p5surgD2M2+pPeUuTu1SnmFBRzdrRXetOJqzs
 oK3IntTPEq2ZDf3ynxV2H6fXjfdPr1cvb6gsO8HP8mpYuCUEI10uti8a0iv+p0jEwh2zzJhtTZ8
 HZS3067Oz7z5bcK0McMBBG+nLkdeGg5rwCIs8e7U1LuRsH0bDa0BXp9rA6KKK+3kuizFBEETtKO
 iH0db+yFwbiEd3WJS+rWVxcDyJcpvVa+/ajd1gPVMvgjdDK9Yb2K8okUUtHyTaJVvbmy+9mLvaC
 wP3f4fLL5zXak2gfan0T53XSognvmXLcWRipLFEx4aaaCa+Ysex7X+Y4Sr1OiNDfQqj0ld/kE3F
 nhjnaQspSzAwh5CKXt/iEn4KBjjaVP+QwQb18+5NsN9oqVM8NTuZxTLuzGool4FfaOnV+1iP8DQ
 MSBxeKoE5DuHoo+QnixKx7LMFGpfT5Qbf4Z9728hheIDMxyhpp3sfc6U//+YMdJbxsNh1Hl9Ngi
 7do8AgglsB43/B+MsBoM5n0We9uG5WEZV20YdXpjakMurLwAhNIbtJV0nqgzUxWHyknyFIAuAX3
 v81gCuR1ekowhRbgkccgsJYVsAh3m2MA3GxW1bt0yYGAQubmRZbKWrnXwaM3Kglbra/ArZRhqY3
 dOW1rxWrzMruKxw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mateusz Jończyk <mat.jonczyk@o2.pl>

This configuration option had no help text, so add it.

CONFIG_EXPERT is enabled on some distribution kernels, so people using a
distribution kernel's configuration as a starting point will see this
option.

Signed-off-by: Mateusz Jończyk <mat.jonczyk@o2.pl>
Signed-off-by: David Heideberg <david@ixit.cz>
---
 arch/x86/Kconfig | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index fbc9ba30fd1cbfb574399a0632b9f77876ba84a8..64a1e00619df95f559488e3004558a7b0f653df3 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -2914,6 +2914,19 @@ config PCI_MMCONFIG
 	default y
 	depends on PCI && (ACPI || JAILHOUSE_GUEST)
 	depends on X86_64 || (PCI_GOANY || PCI_GOMMCONFIG)
+	help
+	  Add support for accessing the PCI configuration space as a memory
+	  mapped area. It is the recommended method if the system supports
+	  this (it must have PCI Express and ACPI for it to be available).
+
+	  In the unlikely case that enabling this configuration option causes
+	  problems, the mechanism can be switched off with the 'pci=nommconf'
+	  command line parameter.
+
+	  Say 'n' only if you are sure that your platform does not support this
+	  access method or you have problems caused by it.
+
+	  Say 'y' otherwise.
 
 config PCI_OLPC
 	def_bool y

-- 
2.49.0

