From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH 0/2] modpost: fix RISC-V randconfig section mismatch false
 positives
Date: Thu, 16 Jul 2026 13:31:48 +0800
Message-Id: <20260716-modpost-v1-0-8eab36cc7310@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMRsWGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc0Mz3dz8lIL84hJdY4MU0xQjixTLFDMTJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tAJEOAGtrAAAA
X-Change-ID: 20260716-modpost-30d5d28d9d64
To: Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kbuild@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784179921; l=1729;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=jrgmCjWRCYkHgrBgI9ADeNJXL3DFWZsSnbuE9Bzc+tc=;
 b=s6auCp5CqXZZZviC++F8fu8iaXugrrqEm4ism6ga+ZXfB5FqqR8/e0vvIzSRyG8UAuEHdh8XD
 jPi/vzdz9PSDNYUdItfeEu2Gwj+ilU89w2B4Uc/DImVTcQFZkuQNVJt
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes two modpost false-positive section mismatch cases seen
with RISC-V randconfig builds.

The first patch filters compiler-generated GCOV symbols and RISC-V local
branch/PC-relative relocations when they point at init or exit sections.
These references can come from instrumentation or local compiler/linker
details rather than from real kernel section lifetime dependencies.

The second patch handles RISC-V relative exception table entries as
R_RISCV_ADD32/R_RISCV_SUB32 relocation pairs. modpost already skipped the
SUB32 half, but still checked the ADD32 symbol directly. After a
relocatable link, that symbol can name an unrelated local debug symbol and
trigger false .debug* section mismatch diagnostics from these __ex_table
relocation pairs.

The issues are reproducible with both GCC 14 and GCC 15. They were
reproduced or validated with:

  - rv32 randconfig, KCONFIG_SEED=277518,
    CONFIG_GCOV_PROFILE_ALL=y, CONFIG_KCOV_INSTRUMENT_ALL=y,
    CONFIG_DEBUG_INFO_BTF=y

  - rv32 randconfig, KCONFIG_SEED=4721,
    CONFIG_MMU=y, CONFIG_DEBUG_INFO=y

With the fixes applied, the corresponding RISC-V randconfig builds complete
successfully. Other unrelated modpost warnings may still remain.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Jia Wang (2):
      modpost: ignore generated GCOV and RISC-V local relocs
      modpost: handle RISC-V relative extable relocations

 scripts/mod/modpost.c | 157 +++++++++++++++++++++++++++++++++++++++++++++++---
 1 file changed, 150 insertions(+), 7 deletions(-)
---
base-commit: 58717b2a1365d06c8c64b72aa948541b53fe31eb
change-id: 20260716-modpost-30d5d28d9d64

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

