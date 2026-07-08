From: Sven Peter <sven@kernel.org>
Date: Wed, 08 Jul 2026 09:15:39 +0200
Subject: [PATCH RFC 3/6] efi: Add EFI_MEMORY_ISA_{MASK,VALID}
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-efi-psci-v1-3-9efb3abf0e4c@kernel.org>
References: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
In-Reply-To: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
To: Mark Rutland <mark.rutland@arm.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Ard Biesheuvel <ardb@kernel.org>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-efi@vger.kernel.org, 
 asahi@lists.linux.dev, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1258; i=sven@kernel.org;
 h=from:subject:message-id; bh=DVNTXLHX1vUyS9zVAhAFUGx9k5ZtrHeeZURle9eN7LM=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ5bvTy0vk+B109JP9a57cmSRU0FFcPODuGU3op9wlAkc+
 nx7XpBbRykLgxgXg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAif68x/GbZ4Jnx49vsfcE3
 NN9sZJhYGCWrrJd+kHFfid3xT0137qowMmxtkvNz41gZJ5MVUrrBNO7Mvf2MfosFnrH/6tz5QmC
 NLxsA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As defined in UEFI 2.10, Section 7.2.3 [1], if EFI_MEMORY_ISA_VALID is
set the memory region is to be mapped using ISA-specific cacheability
attributes found in EFI_MEMORY_ISA_MASK. On AArch64, these bits are e.g.
defined as the attributes stored in MAIR [2].

[1] https://uefi.org/specs/UEFI/2.10/07_Services_Boot_Services.html#efi-boot-services-getmemorymap
[2] https://uefi.org/specs/UEFI/2.10/02_Overview.html#memory-types

Signed-off-by: Sven Peter <sven@kernel.org>
---
 include/linux/efi.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/include/linux/efi.h b/include/linux/efi.h
index f3db3a18b540..882148114068 100644
--- a/include/linux/efi.h
+++ b/include/linux/efi.h
@@ -128,6 +128,8 @@ typedef	struct {
 #define EFI_MEMORY_SP			BIT_ULL(18)	/* soft reserved */
 #define EFI_MEMORY_CPU_CRYPTO		BIT_ULL(19)	/* supports encryption */
 #define EFI_MEMORY_HOT_PLUGGABLE	BIT_ULL(20)	/* supports unplugging at runtime */
+#define EFI_MEMORY_ISA_MASK		GENMASK_ULL(59, 44)	/* ISA-specific attributes */
+#define EFI_MEMORY_ISA_VALID		BIT_ULL(62)	/* EFI_MEMORY_ISA_MASK bits are valid */
 #define EFI_MEMORY_RUNTIME		BIT_ULL(63)	/* range requires runtime mapping */
 
 #define EFI_MEMORY_DESCRIPTOR_VERSION	1

-- 
2.55.0

