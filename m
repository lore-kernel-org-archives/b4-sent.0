From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v2 0/3] Audio and other peripherals on Orange Pi Zero
Date: Sat, 09 Aug 2025 18:18:05 +0200
Message-Id: <20250809-opz-audio-v2-0-f4fd15552a82@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAL10l2gC/03MQQ7CIBCF4as0sxYDSC3tynuYLgod7WyAQCVqw
 93FJiYu/5eXb4OEkTDB0GwQMVMi72rIQwN2mdwdGc21QXLZciU65sObTY+ZPNM916q32hiJUP8
 h4o2eu3Uday+UVh9fO53Fd/0p+k/JggmmUJ+NaY3tTuoSfFrRHx2uMJZSPpkBRDSjAAAA
X-Change-ID: 20250417-opz-audio-890849c8bb2e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@csie.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754756302; l=1005;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Bwb6t2YuRUfjH9rtbL/iknXzFlmnm4YAv6kHXJJPfCc=;
 b=M7EvQXq4AITTYxKXjvWKmbdYsFY8YmBweMFkH+7/uCjZJtk5oXQhfg7cjblavaI1YXjCEMJfv
 7Qn+cYdiikoA1sq1BfTl9mPzw6SGataXmHp07VPaQvx189eg50rM062
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Rebase on (almost) 6.17-rc1
- Disable audio pins by default
- Provide separate DT overlay for the Orange Pi Zero Interface Board
- Link to v1: https://lore.kernel.org/r/20250418-opz-audio-v1-1-4e86bb5bc734@posteo.net

---
J. Neuschäfer (3):
      ARM: dts: allwinner: orangepi-zero: Add default audio routing
      ARM: dts: allwinner: orangepi-zero2: Add default audio routing
      ARM: dts: allwinner: Add Orange Pi Zero Interface Board overlay

 arch/arm/boot/dts/allwinner/Makefile               |  7 ++++
 .../dts/allwinner/sun8i-h2-plus-orangepi-zero.dts  | 14 +++++++
 .../dts/allwinner/sun8i-h3-orangepi-zero-plus2.dts | 14 +++++++
 .../sun8i-orangepi-zero-interface-board.dtso       | 46 ++++++++++++++++++++++
 4 files changed, 81 insertions(+)
---
base-commit: 36c31984cca32c5d9720c8c1eb5bd17fa915419f
change-id: 20250417-opz-audio-890849c8bb2e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

