From: David Heidelberg <david@ixit.cz>
Date: Fri, 21 Mar 2025 21:48:44 +0100
Subject: [PATCH v3 2/7] x86/Kconfig: Always enable ARCH_SPARSEMEM_ENABLE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250321-x86_x2apic-v3-2-b0cbaa6fa338@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=883; i=david@ixit.cz;
 h=from:subject:message-id; bh=gBFoQ/Mwva6BqlKESKTHfSvabeRcf/AwbnhAOXp5CGU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn3dCuQb2kZ5vosmfdS0lmBu5xbidcEqsWd0qx7
 sBiVrjtvOGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ93QrgAKCRBgAj/E00kg
 chphD/sHnhrT5lKYoLP1lD5ks8ntjQlQanb00MDQ4O0VvLzDzi/DYI2S/89wQ8+sBhbXMMEfR51
 NoSxZHNG5b5nAyB/ymHNaVE0arQrMCTaHpLN5pr9fwe95aaVleN0Swf1F8cMMdp5H7uG5PzK1f9
 DUToZE003eHrY8komQjf3QqG0+4dizLp03NN4vdnhvjAfS6nxDy8j8RIUtJNBgYcOHoxeGbhcX/
 YOedr5LyGP8pgbA3lOQD3MdkTgIcwaSaTCmYL8gFmcy3sx257BpZ+i3PI6459s/+T3v2f8oh3yI
 yYqrxfJVK7weNw2aJFou/QgkHlVCHKEZ7AYLyMtp7jR1bYqTSDfqNZa+3jHn2mXxuL5jjV82o+d
 IpyKUM8lxnUQuN32b4PP3U+q+bgVS+KJZrID0yqbtYSWGUVonro+HSHHH36xyCn7xPHr+ticYIl
 PXkA1vF/wwZROSQpfcCVrk/vRtP5h3Q0g4jPPI+MhJjkFypazP5bbWR7i3yh5k5vhwJIQUYlDwD
 rI9sbKW0F6wWB/DRnIT30i6DGJ+ILcQ5hVx+i0w8E2j1uJGSMeXZBFX8dDp77L67DQC1RcTCbe0
 QQ0avnaCqdOMXFQIjGUGzrutuMamFWwoW3bBRGH6BvCNWj2a79NOcBg+E0iY3Il9knjywrhtl0y
 b1tT0OtiRkJcQTg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mateusz Jończyk <mat.jonczyk@o2.pl>

It appears that (X86_64 || X86_32) is always true on x86.

This logical OR directive was introduced in
commit 6ea3038648da ("arch/x86: remove depends on CONFIG_EXPERIMENTAL")
probably by a trivial mistake.

Fixes: 6ea3038648da ("arch/x86: remove depends on CONFIG_EXPERIMENTAL")
Signed-off-by: Mateusz Jończyk <mat.jonczyk@o2.pl>
Signed-off-by: David Heideberg <david@ixit.cz>
---
 arch/x86/Kconfig | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index 10f48afd67f6fd7d250f2effddcc5bc927b057af..38a915f739af45f1b23a197032ce6cff94fdd81d 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -1574,7 +1574,6 @@ config ARCH_FLATMEM_ENABLE
 
 config ARCH_SPARSEMEM_ENABLE
 	def_bool y
-	depends on X86_64 || NUMA || X86_32
 	select SPARSEMEM_STATIC if X86_32
 	select SPARSEMEM_VMEMMAP_ENABLE if X86_64
 

-- 
2.49.0

