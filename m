From: David Heidelberg <david@ixit.cz>
Date: Fri, 21 Mar 2025 21:48:49 +0100
Subject: [PATCH v3 7/7] x86/Kconfig: Document release year of glibc 2.3.3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250321-x86_x2apic-v3-7-b0cbaa6fa338@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=813; i=david@ixit.cz;
 h=from:subject:message-id; bh=9OvHfX7hjKPWyoFcg1JfBC1j93k9cRQ1pVfK3nHdJAs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn3dCui3quEeZQO7ntSazprt9cEZVgq81Us4dJa
 OTGelM2MDKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ93QrgAKCRBgAj/E00kg
 cniOD/48XqqJrrrAlESfe/SxdiR6zjYr5kHsGQkEcmRkUnYaP/g5B3MKUkMr7aAcgXKHbVEnbVO
 SInWdtQ6aGqNpatjC4G4CeEiw6MEqaRNrJbYYKsvarFpRSvfR2WBCCc4+HwYqK4NfFrUeH5P1kg
 6ZQSGWCcnSuVoyMlw22owOb3NMaEHqXKFvsn3PqJNVIlzcu7s9cqGezC4Jjh4wzdYp0nDoRBcZA
 IhE7c5mG8JnDK5P4Y1M4dAyQ14Klp1YbLHh9a1OZJnbSNNL2g+hTvVH+4aN+YLrn/qn6ieQxopl
 Rq2ywqWI0seE54VsCp8jsM00FrFq6d/puV9qxZpK+CFZ9YY/nPIVmP8CnekzdgecFwkwIcZSKpr
 NMxOTPgarQOoYZ5FqlysJ4goTDRq0oIk3IMESK6GVW0Fc1HtqLDtLLfVOfKnlHIyIlzTdCxOdrE
 0HMsi5+MOoOpTwA03izg0aXKhbVpzUroRpPraqbkIfjJXsbeH5+TN6c/IPharOUgZtIY1/KA+CY
 bIDVvzL90uhYHGtUqB/4Q9y0bYFI8pBKwy/0nnQo6dsGIfrpEdm9kHy79fgYbhikIdtJRspfvZz
 bwgEFEnqHraG2vZYDIOwKHj6/me8b4Mki9P4bMhzXeUCpGIGYwalRKI7zFLjeOTZ4xQzwzLC+S2
 kn1fpdXFwpseH9Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mateusz Jończyk <mat.jonczyk@o2.pl>

I wonder how many people were checking their glibc version when
considering whether to enable this option.

Signed-off-by: Mateusz Jończyk <mat.jonczyk@o2.pl>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/x86/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index ba6ba3a7011554d9cb58fb0acf48d541da8ed69b..22dd962f8e5c86741a512e12596bd940cd1dae97 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -2225,7 +2225,7 @@ config HOTPLUG_CPU
 
 config COMPAT_VDSO
 	def_bool n
-	prompt "Disable the 32-bit vDSO (needed for glibc 2.3.3)"
+	prompt "Workaround for glibc 2.3.2 / 2.3.3 (released in year 2003/2004)"
 	depends on COMPAT_32
 	help
 	  Certain buggy versions of glibc will crash if they are

-- 
2.49.0

