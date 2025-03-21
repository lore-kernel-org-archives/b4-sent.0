From: David Heidelberg <david@ixit.cz>
Date: Fri, 21 Mar 2025 21:48:46 +0100
Subject: [PATCH v3 4/7] x86/Kconfig: Update lists in X86_EXTENDED_PLATFORM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250321-x86_x2apic-v3-4-b0cbaa6fa338@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1648; i=david@ixit.cz;
 h=from:subject:message-id; bh=nrv4SmvAYUhUrihtUik+drIq1LZYFKFcyzZRBUmd5Mg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn3dCuv8nW+5F3N0iGdtqB1flVbmyxDXJkJe+1d
 b1JkzGYJ5iJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ93QrgAKCRBgAj/E00kg
 cjmBD/9pkiNdGCnuFiEQy9B8w/zs2Z3SLBwiQar0/WUwmysqq7Wrj3muZ2PaDEg7wygLs8/Vhe3
 1n0RnQcnfEbhi17CKmvoJhi7ItXZUUojjbSqXUGDkQ/BADCofv3tRwD+hmNqUYF+E+P5A2fXmy+
 3C5veQBJavPWtnkGQqbCk1ECq9Zg5bZeTntXH0g+zJbcPzqbtK7WHOe7aUyVpHv7gtbyst5rGWS
 VQx7qekMLZFi7BHz5dsoBy/jB1aAR2xsybYA6bKxB3Be0H5Pw5lM7QQED2mGtYY9El5+7eD/cjF
 RwGPFUvpQ6hxSRHx99+Y4U/ptgI7gCNzVa18Qc0L/MujhYDHWepBcPjdnk3dawDiLYf/Ao39chV
 3MPPNfZ6HZ5KF/nub8CwmMFTRw3xEb14D9AhW6JAG783ucVCDof3M/Hv1uQQMpXv2bXyEbDMOpR
 tKUB4NVKu9RUzQ3kOcD12OzFazIRj9xvvddC+4XSNZn4GO8G7wrtHMueoVGK54pV/Cr9zS/pLuc
 8ype6q0gl6f1R9unza+JI/31sKUcPs2L7xkuQYw8j+J4xUCOfxy6yRxzAH8XHEoKyFoMmpaXVUz
 mPM1dJIUWQNS4zba90WYUEBnjbxtMFuFY9C1EVxVMmDx4Swa836lWpiPGoFtMnAD9sGFM95J9Zo
 +LSdC4bJZZWyL1A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mateusz Jończyk <mat.jonczyk@o2.pl>

The order of the entries matches the order they appear in Kconfig.

In 2011, AMD Elan was moved to Kconfig.cpu and the dependency on
X86_EXTENDED_PLATFORM was dropped in
commit ce9c99af8d4b ("x86, cpu: Move AMD Elan Kconfig under "Processor family"")

Support for Moorestown MID devices was removed in 2012 in
commit 1a8359e411eb ("x86/mid: Remove Intel Moorestown")

SGI 320/540 (Visual Workstation) was removed in 2014 in
commit c5f9ee3d665a ("x86, platforms: Remove SGI Visual Workstation")

Signed-off-by: Mateusz Jończyk <mat.jonczyk@o2.pl>
Signed-off-by: David Heideberg <david@ixit.cz>
---
 arch/x86/Kconfig | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index 9e5dea7c9fd7aeceb727f4c372c8880c9182f7f2..fbc9ba30fd1cbfb574399a0632b9f77876ba84a8 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -553,16 +553,20 @@ config X86_EXTENDED_PLATFORM
 	  CONFIG_64BIT.
 
 	  32-bit platforms (CONFIG_64BIT=n):
-		Goldfish (Android emulator)
-		AMD Elan
+		Goldfish (mostly Android emulator)
+		Intel CE media processor (CE4100) SoC
+		Intel MID (Mobile Internet Device)
+		Intel Quark
 		RDC R-321x SoC
-		SGI 320/540 (Visual Workstation)
+		STA2X11-based (e.g. Northville)
 
 	  64-bit platforms (CONFIG_64BIT=y):
 		Numascale NumaChip
 		ScaleMP vSMP
 		SGI Ultraviolet
 		Merrifield/Moorefield MID devices
+		Goldfish (mostly Android emulator)
+		Intel MID (Mobile Internet Device)
 
 	  If you have one of these systems, or if you want to build a
 	  generic distribution kernel, say Y here - otherwise say N.

-- 
2.49.0

