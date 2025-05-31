From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/2] arm: armv7: fix a bug that prevents CONFIG_BLOBLIST
 and CONFIG_POSITION_INDEPENDENT to be enabled together
Date: Sat, 31 May 2025 21:10:01 +0800
Message-Id: <20250531-pie_blob_fix-v1-0-7b4a37987dbc@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKn/OmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDUyNL3YLM1PiknPyk+LTMCt1EM0MjI8tki7TkZDMloJaColSgMNi46Nj
 aWgD34gdsXgAAAA==
To: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Raymond Mao <raymond.mao@linaro.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748697019; l=599;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=J6wkmFfInW7sCuAc23x3i6ek8Bjdyzz/1bK11sB27nc=;
 b=mJa2pGoYHUF9D8ixQXjkTEDmNwABLppxunfYU5k59XybeIAMVyvVOeks4zWxYsNIbforoBURT
 CXf28k/4RSoB3jZ6376k/PTiOfG+Pal0q1BDvE/UhBZb0A494c19+DW
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset also enables CONFIG_POSITION_INDEPENDENT for qemu boards
to avoid similar issues to happen again in the future.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      arm: armv7: restore section to .text after saved_args
      arm: qemu: Add imply CONFIG_POSITION_INDEPENDENT

 arch/arm/Kconfig           | 1 +
 arch/arm/cpu/armv7/start.S | 2 ++
 2 files changed, 3 insertions(+)
---
base-commit: 93905ab6e7564089f5d7b703b660464d675e5ab0
change-id: 20250529-pie_blob_fix-a61229c8fcc6

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

