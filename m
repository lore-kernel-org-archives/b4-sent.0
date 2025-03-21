From: David Heidelberg <david@ixit.cz>
Date: Fri, 21 Mar 2025 21:48:48 +0100
Subject: [PATCH v3 6/7] x86/Kconfig: Make CONFIG_PCI_CNB20LE_QUIRK depend
 on X86_32
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250321-x86_x2apic-v3-6-b0cbaa6fa338@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3223; i=david@ixit.cz;
 h=from:subject:message-id; bh=7AuR1hNQHR8/gFLUhnVuBp1tH25Vf1c/ieb+mgzxiH8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn3dCuOaoPF9BmpnMsvQu8AmMCME/A9yE3QcM0C
 E1IkN2uCHCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ93QrgAKCRBgAj/E00kg
 ckixD/wP8wbyrw8fWmN/lzMqlM0vYxDzeVQOx1bZ1UW4lf4vSSlEPKGJoGXnJ7Ei15xSL4r3WUa
 Rt20q8NuZQL4l0QQomrMF94Hc8njhRoiGO7D7frk5IUr8GjpdTQ8BgYUt+qYbrhtPkBVb9haPIY
 ipsw/lP/URrsMGZNEQ5HRx5OeagcjdJTcmDMq26Pr9kS4UheOP6uEVO819z+R0bJXBG3gC3t/8j
 4t8mbnSWSOlVodYj89602r4drjja40oO0pPb/7WUK+d01wTSe2mYUp1oBtIwuD3hnBsVnVpIKUM
 eJwKw5RUN/elMQNTtcu5hntoeaDSeGnme2tasCUbJd3gXAAl0g1Bqwxr/TjpaHPNIo1vyreDR2V
 Jor4zgnATt7GoiF649PjgPTwPq+Gg/BfPO0QFnXKaexmfMEVgnwFOwt+wRUEHeUH0JUNqWKoJxs
 Zko/QLuD7MJl/rMgyg1an3/y0vkbTEW9FucJffQVpP91675jWVAQwe46NGc5GvI3dAtrMHe6n89
 ukCpUTEEB9DNE4ggHLETDpTA2iObNBkBJfTimC3hbNYzD525wYcVhu2R3anT4jFqDQM9moIOOA8
 dUEHrVGDl0YLybY4NZCems32TAH3NIXDc3lhDr+0L3jHDdCbPdji1pjhdmz9PKVD73FS9EseSSE
 d8rK2w/7xkUwOjQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mateusz Jończyk <mat.jonczyk@o2.pl>

I was unable to find a good description of the ServerWorks CNB20LE
chipset. However, it was probably exclusively used with the Pentium III
processor (this CPU model was used in all references to it that I
found where the CPU model was provided: dmesgs in [1] and [2];
[3] page 2; [4]-[7]).

As is widely known, the Pentium III processor did not support the 64-bit
mode, support for which was introduced by Intel a couple of years later.
So it is safe to assume that no systems with the CNB20LE chipset have
amd64 and the CONFIG_PCI_CNB20LE_QUIRK may now depend on X86_32.

Additionally, I have determined that most computers with the CNB20LE
chipset did have ACPI support and this driver was inactive on them.
I have submitted a patch to remove this driver, but it was met with
resistance [8].

[1] Jim Studt, Re: Problem with ServerWorks CNB20LE and lost interrupts
Linux Kernel Mailing List, https://lkml.org/lkml/2002/1/11/111

[2] RedHat Bug 665109 - e100 problems on old Compaq Proliant DL320
https://bugzilla.redhat.com/show_bug.cgi?id=665109

[3] R. Hughes-Jones, S. Dallison, G. Fairey, Performance Measurements on
Gigabit Ethernet NICs and Server Quality Motherboards,
http://datatag.web.cern.ch/papers/pfldnet2003-rhj.doc

[4] "Hardware for Linux",
Probe #d6b5151873 of Intel STL2-bd A28808-302 Desktop Computer (STL2)
https://linux-hardware.org/?probe=d6b5151873

[5] "Hardware for Linux", Probe #0b5d843f10 of Compaq ProLiant DL380
https://linux-hardware.org/?probe=0b5d843f10

[6] Ubuntu Forums, Dell Poweredge 2400 - Adaptec SCSI Bus AIC-7880
https://ubuntuforums.org/showthread.php?t=1689552

[7] Ira W. Snyder, "BISECTED: 2.6.35 (and -git) fail to boot: APIC problems"
https://lkml.org/lkml/2010/8/13/220

[8] Bjorn Helgaas, "Re: [PATCH] x86/pci: drop ServerWorks / Broadcom
CNB20LE PCI host bridge driver"
https://lore.kernel.org/lkml/20220318165535.GA840063@bhelgaas/T/

Signed-off-by: Mateusz Jończyk <mat.jonczyk@o2.pl>
Signed-off-by: David Heideberg <david@ixit.cz>
---
 arch/x86/Kconfig | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index 64a1e00619df95f559488e3004558a7b0f653df3..ba6ba3a7011554d9cb58fb0acf48d541da8ed69b 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -2941,13 +2941,21 @@ config MMCONF_FAM10H
 	depends on X86_64 && PCI_MMCONFIG && ACPI
 
 config PCI_CNB20LE_QUIRK
-	bool "Read CNB20LE Host Bridge Windows" if EXPERT
-	depends on PCI
+	bool "Read PCI host bridge windows from the CNB20LE chipset" if EXPERT
+	depends on X86_32 && PCI
 	help
 	  Read the PCI windows out of the CNB20LE host bridge. This allows
 	  PCI hotplug to work on systems with the CNB20LE chipset which do
 	  not have ACPI.
 
+	  The ServerWorks (later Broadcom) CNB20LE was a chipset designed
+	  most probably only for Pentium III.
+
+	  To find out if you have such a chipset, search for a PCI device with
+	  1166:0009 PCI IDs, for example by executing
+		lspci -nn | grep '1166:0009'
+	  The code is inactive if there is none.
+
 	  There's no public spec for this chipset, and this functionality
 	  is known to be incomplete.
 

-- 
2.49.0

