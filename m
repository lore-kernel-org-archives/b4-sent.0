From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH v3 0/5] arm64: dts: exynos: add initial support for Samsung
 Galaxy Watch FE
Date: Fri, 30 Oct 2026 20:33:55 +0000
Message-Id: <20261030-for-next-lucky7-v3-0-81e02272ce69@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADP/5GoC/2XNQQ6CMBQE0KuYri1pSxFx5T2MC375hapQ00IDI
 dzdgtENy0lm3szEozPoyeUwE4fBeGO7GNLjgaim7GqkpoqZCCZO7Mwzqq2jHY49fQ3qOeUUM9B
 pkTGoAElcvR1qM27i7f7NfoAHqn5l1kZjfG/dtF0GvvZ+er7TA6eMSqE1CMg5lOLaYgvoEu11Y
 l1N1osg/ghnvNgjIiJKoipBAldS7ZBlWT5Slfx2CgEAAA==
X-Change-ID: 20260815-for-next-lucky7-e5bf3950bdbe
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3662;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=ShZllIGN42iGEx7W+Ypwb4WSw6LjsTQdyvwIRirngDE=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq5P880mkB/Tc1KaQVPmBl8Rnywzg0CQcgUXZhX
 J+Uzlwnj2aJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCauT/PBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+ufLg/9EPFDmSJq2MS0IynMfsABflaLewcHokp
 i0cBVpvY5cR8Tm+8u8a2HtZXoHEX4rEDqmYELCyBrkv6aZ6JBw/IGx7uGk3L3ndlWkZ8G1O+9XV
 iOS2iarSnC1Y5/8hPfs7PkYkNJ9FwRVEQ6f/ldon+Tc4TDYFHAlNxMRVJT8ZWdI75zJF/s+6PdN
 gaeg/5WQ4dKKCirTAGWl91rHElvZ4vB8+ivJ/fCLn5QjTxDgU4wtMAzUjiwof10WBy8oJkjYvu0
 3BqNGntJUufgZ7zet+aYwddbaTycwiJQdBgM1A2EjVM20UpJJxxWyQ4ho90+lxw8e4x7/9BLqtX
 waby6tQ9mJpahlSjem0uCY+IN5x2PKHKCdquW/DscqEwglwUZ+4S4r9+I0XSSxd+58dCviCkve9
 tgsqVSOiI7FCsLAtWAo8Dk8SVMCpEgQ6hU+kA84jQQCeKBt7Wi8xMGa4TvlXkCxEseuYEXWiJpb
 1RvBQc72uAe4rsj86Q3wRZR6ZIKkffBjVgbl9LL1I8zc4x02QeKyY9mA+iLyPKxxOhyg7no95TJ
 R24TvDkdLaC8z64OiRvKAPA2CiqrTWtTuAgto5bATlRad/ZQHGpw2OHWFZJQ5ZU7zrVEz0RJEjb
 wTEwPBZBdHER1GBkKfAJya4bD/2nXjbcQSny9OJI25sDVm3kLbEA=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi there,

This patchset adds initial support for the Exynos5515 SoC, along with
support for the Samsung Galaxy Watch FE (codenamed lucky7), which uses
this SoC.

Support for the following is added:
- Bootloader framebuffer
- Both CPU cores
- Memory
- Generic timer
- CMU_TOP, CMU_FSYS, CMU_PERI clock management units
- ChipID

Currently, these device trees support booting the device to an initramfs.

There are quite a few regions of reserved memory, where usage of them
can crash the system and/or cause unexpected behaviour. Currently, most
of them are named "misc-rmem@addr". They will be given names as their
accompanying device drivers are added and their purpose becomes apparent.
If you would like them named differently, feel free to let me know.

The VGIC maintenance interrupt seems to be unavailable on this SoC.
I cannot find any reference to it, nor usage of it, anywhere.
It *could* very well still exist, but it is a mystery for now (and also
not a *huge* deal on a low-power SoC designed for smartwatches).

I am getting checkpatch warnings on this patchset advising to check
MAINTAINERS as new files were added, but I am ignoring them as the
entirety of arch/arm64/boot/dts/exynos is covered already.

Kind regards,
- Aiden Isik

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
Changes in v3:
- Remove watchdog node
- Add required clock properties to sysreg_peri and sysreg_fsys
- Use arm,cortex-a55-pmu compatible instead of arm,armv8-pmuv3 for pmu node
- Fix missing Makefile entry
- Link to v2: https://patch.msgid.link/20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org

Changes in v2:
- Fix patchset title
- Fix DCO email
- Fix style issues reported by dt-check-style in strict mode
- Added patches which were accidentally dropped in v1
- Fix reserved memory and make all memory accessible in the memory node
- Remove redundant PSCI 1.0 cpu_* function IDs
- Extend GIC registers to correct size
- Correct GIC unit address
- Correct CPU unit address
- Document unavailable VGIC maintenance interrupt
- Remove references to dependencies which have since been merged to this tree
- Link to v1: https://patch.msgid.link/20260817-for-next-lucky7-v1-0-42ffb2b71ba2@member.fsf.org

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Peter Griffin <peter.griffin@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-samsung-soc@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Aiden Isik (5):
      dt-bindings: soc: samsung: exynos-sysreg: Add compatibles for Exynos5515
      dt-bindings: soc: samsung: exynos-pmu: Add Exynos5515 compatible
      dt-bindings: arm: samsung: Add lucky7 board binding
      arm64: dts: exynos: Add initial support for Exynos5515 SoC
      arm64: dts: exynos: Add initial support for Samsung Galaxy Watch FE

 .../bindings/arm/samsung/samsung-boards.yaml       |   6 +
 .../bindings/soc/samsung/exynos-pmu.yaml           |   1 +
 .../soc/samsung/samsung,exynos-sysreg.yaml         |   5 +
 arch/arm64/boot/dts/exynos/Makefile                |   1 +
 arch/arm64/boot/dts/exynos/exynos5515-lucky7.dts   | 215 +++++++++++++++++++++
 arch/arm64/boot/dts/exynos/exynos5515.dtsi         | 178 +++++++++++++++++
 6 files changed, 406 insertions(+)
---
base-commit: 993e1bec85faedf90c5d27480793084e54357c09
change-id: 20260815-for-next-lucky7-e5bf3950bdbe

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

