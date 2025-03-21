From: David Heidelberg <david@ixit.cz>
Date: Fri, 21 Mar 2025 21:48:45 +0100
Subject: [PATCH v3 3/7] x86/Kconfig: Move all X86_EXTENDED_PLATFORM options
 together
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250321-x86_x2apic-v3-3-b0cbaa6fa338@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1560; i=david@ixit.cz;
 h=from:subject:message-id; bh=51c/Gs0I0J1wJoEtVvTIk8/MWpkL2eyjSInCszhj468=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn3dCuwOuK64hfcf7R2QE3YAT0lY+6Oelez7pDf
 JxQe6F2bFiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ93QrgAKCRBgAj/E00kg
 cgO3D/4pWKx9KjeMiaHWROemKqSuG5xlScxmTbFuezCyyc57EgB9x6sxlndj70T4aaYgj9/18xl
 EnuAb3RPYO7oWEFFza8U3CKko+i9GCEYwZrSnT7NDMr1dFjcTtaOlzHCb9kcPoKjAAYO+shWNXy
 OcjEuNsG2qBkEpMsb0LrTAzXUxLoMQrcfs14S94qpC2vPirb2rznBk4acrRxWxpM3L2Ce6gVM2s
 FLAiAjJk+Xgun3Z3mZjHD6m0jGlVrP7+YdBoWbacphK8+fFFtxZLOl4D2Mx+gMVN62g1kp5E2+U
 mztQDh6bGETmRnNI1zTrX2x69WtWKtxQ7ihSnG4eC9apmKaaTAsNTtjbJb9CwjMWrZX8baLkKiE
 /3pnNDgS98yMh5tbyFUZXoR37Q2gzaVCdZ92mhXkYneTAFbEMN7DEMVxLsqUXV7dXpZXOLKy/IL
 iJgtl0OKxBVdzADj3zSvAmNkyA8M0iEdNWLhVkzpOOD2N+wE9M/sswpd3J9jh1ZNiYklPZ507XX
 FjdLASOl962aBHt4SvoqNYwpQATzUgncx1lTJCNivnH1a0X2ceqjcCQgpodG8+tyPo4sI4veBOL
 GdGfqzwKcODH49y/Ffqwo3HYcw5ockXmJLM8QgtX79Eu+sVEwSwzETjG3XtyVkx56Fiz3Meri/+
 aSXl0cDeI1jP83w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mateusz Jończyk <mat.jonczyk@o2.pl>

so that these options will be displayed together in menuconfig etc.

Signed-off-by: Mateusz Jończyk <mat.jonczyk@o2.pl>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/x86/Kconfig | 22 +++++++++++-----------
 1 file changed, 11 insertions(+), 11 deletions(-)

diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index 38a915f739af45f1b23a197032ce6cff94fdd81d..9e5dea7c9fd7aeceb727f4c372c8880c9182f7f2 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -676,6 +676,17 @@ config X86_INTEL_QUARK
 	  Say Y here if you have a Quark based system such as the Arduino
 	  compatible Intel Galileo.
 
+config X86_RDC321X
+	bool "RDC R-321x SoC"
+	depends on X86_32
+	depends on X86_EXTENDED_PLATFORM
+	select M486
+	select X86_REBOOTFIXUPS
+	help
+	  This option is needed for RDC R-321x system-on-chip, also known
+	  as R-8610-(G).
+	  If you don't have one of these chips, you should say N here.
+
 config X86_INTEL_LPSS
 	bool "Intel Low Power Subsystem Support"
 	depends on X86 && ACPI && PCI
@@ -729,17 +740,6 @@ config IOSF_MBI_DEBUG
 
 	  If you don't require the option or are in doubt, say N.
 
-config X86_RDC321X
-	bool "RDC R-321x SoC"
-	depends on X86_32
-	depends on X86_EXTENDED_PLATFORM
-	select M486
-	select X86_REBOOTFIXUPS
-	help
-	  This option is needed for RDC R-321x system-on-chip, also known
-	  as R-8610-(G).
-	  If you don't have one of these chips, you should say N here.
-
 config X86_SUPPORTS_MEMORY_FAILURE
 	def_bool y
 	# MCE code calls memory_failure():

-- 
2.49.0

