From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/3] cmd: ufetch improvements
Date: Thu, 05 Dec 2024 19:35:32 +0100
Message-Id: <20241205-ufetch-v1-0-df861318bd49@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHTyUWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDIwNj3dK01JLkDF1jI7NUc3PDJCOzxBQloOKCotS0zAqwQdGxtbUAPxV
 GdlgAAAA=
X-Change-ID: 20241203-ufetch-326e771b26ad
To: Caleb Connolly <caleb.connolly@linaro.org>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733423734; l=597;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=NFIN77ZSdu76R2hQht1rdHGOicutB88LEt1e23u2/cI=;
 b=6g0ONJ0lmFX/lJYvRVOnkIpq9AHY87wtLqjrRpC2GutCLhXp2JLgjcyDwa5/oL/1AM7lAiEpS
 aTY9aHB4A+DCiGk0nfYczR1jSEkhBdUzNCg9O7Tc6kuTtWIoPPfHknN
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Following the recent addition of the "ufetch" command, this patchset
improves it in a few ways.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (3):
      cmd: ufetch: Fix type mismatch on 32-bit
      cmd: Allow building ufetch without CONFIG_BLK
      cmd: ufetch: Show CPU architecture under "CPU"

 cmd/Kconfig  |  1 -
 cmd/ufetch.c | 14 +++++++++-----
 2 files changed, 9 insertions(+), 6 deletions(-)
---
base-commit: e5c1c2c6d9da79d874015f6d33fa2c7a34899733
change-id: 20241203-ufetch-326e771b26ad

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

