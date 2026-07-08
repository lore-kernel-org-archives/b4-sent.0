From: Sven Peter <sven@kernel.org>
Subject: [PATCH RFC 0/6] PSCI-via-EFI to support firmware and kernel
 sharing EL2 for Apple Silicon
Date: Wed, 08 Jul 2026 09:15:36 +0200
Message-Id: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMyNT3dS0TN2C4uRM3UTLJDPzpDSzNEMTUyWg8oIioFQF2KhopSA3Z6X
 Y2loAT/7/NF8AAAA=
X-Change-ID: 20260625-efi-psci-a9b67bf6f145
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3357; i=sven@kernel.org;
 h=from:subject:message-id; bh=ByYtCtKpL5zN/yGVXFT5sli8OKOR0P5NbnNTzjELoN0=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ5bvT5WlF8I4rk6Sn5nG6cMjrV3d2vA75pVuJfeDjve1K
 1ZrnrPqKGVhEONikBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAExkrSEjw2P1OXzND6zaJ9/+
 pXRxV4RW6oRK9u44du2vsQZlq27XbWb4KzDz0GxmlsYNH4rEWN7utj4oLCNjHflwftn5nWtOMvs
 msQIA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Usually, idle and sleep state are implemented in firmware running in
e.g. EL3 with the kernel trapping into that from EL2. Unfortunately,
there's no EL3 on Apple Silicon machines and we'd rather not run the
kernel in EL1 since this would result in losing KVM support.

While the shallower states could be implemented inside a custom cpuidle
driver (like we do downstream, see [1]) the deeper states result in a
complete loss of state and require bootstraping the cores again which is
quite involved. So instead we need some way to call back into our
open-source firmware to be able to handle that. This is even more
important for M4+ which don't even support the architectural wfi anymore
and always lose state when that instruction is executed.

Luckily, EFI runtime services provide much of scaffolding we need,
namely a way to keep some code and data mapped and the ability to jump
into there from inside the kernel.

This series adds a custom EFI table that points to a PSCI entry point
(plus some other stuff that has to be available before EFI runtime
services are set up) and adds support for this new conduit to the psci
code. We can't directly use the normal EFI runtime path because that one
takes a sleeping lock and we need to be able to call into PSCI from
atomic context during e.g. cpu bringup or during idle.
It also adds support for specifying the specific MAIR attributes for EFI
runtime mappings as defined in the latest UEFI spec since Apple Silicon
is rather allergic to using Device-nGnRnE vs. Device-nGnRE for its MMIO.

This all results in a surprisingly small diffstat. I believe this
approach was originally suggested in some IRC discussion years ago,
possibly by Ard, but I can't find the old logs anymore.
Happy to add a Suggested-by tag though if anyone remembers.

The firmware implementation I used for testing can be found at [2] and
the full kernel tree with this series applied at [3].

Best,

Sven

[1] https://github.com/AsahiLinux/linux/blob/asahi/drivers/cpuidle/cpuidle-apple.c
[2] https://github.com/AsahiLinux/m1n1/tree/psci-via-efi
[3] https://git.kernel.org/pub/scm/linux/kernel/git/sven/linux.git/log/?h=efi-psci

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (6):
      dt-bindings: arm: psci: Add EFI conduit
      arm64/efi: Add and parse custom PSCI EFI configuration table
      efi: Add EFI_MEMORY_ISA_{MASK,VALID}
      arm64/efi: Honor EFI_MEMORY_ISA_MASK for Device-nGnRnE vs -nGnRE
      firmware/psci: Add EFI runtime conduit
      arm64: dts: apple: t8103: Add PSCI and CPU idle states

 Documentation/devicetree/bindings/arm/psci.yaml | 12 ++++
 arch/arm64/boot/dts/apple/t8103.dtsi            | 51 ++++++++++++---
 arch/arm64/include/asm/efi.h                    | 56 +++++++++++++++++
 arch/arm64/kernel/efi.c                         | 82 ++++++++++++++++++++++++-
 arch/arm64/kernel/setup.c                       |  2 +-
 drivers/firmware/psci/psci.c                    | 64 +++++++++++++++++++
 include/linux/arm-smccc.h                       |  1 +
 include/linux/efi.h                             |  3 +
 8 files changed, 261 insertions(+), 10 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260625-efi-psci-a9b67bf6f145

Best regards,
-- 
Sven Peter <sven@kernel.org>

