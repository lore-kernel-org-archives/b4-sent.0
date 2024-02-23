From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/2] simple-pm-bus: deassert resets if possible
Date: Fri, 23 Feb 2024 18:10:18 +0800
Message-Id: <20240223-b4-bus-v2-0-da8ba83c1a5f@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAApv2GUC/2XMQQ6CMBCF4auQWVtTpi0YV97DsCilyERlTAuNh
 vTuVrYu/5eXb4PoA/kI52qD4BNF4rkEHipwk51vXtBQGlCilohK9Fr0axSDcc3YGoumtlDOr+B
 Heu/QtSs9UVw4fHY31b/1j0i1kAJPUjllnW5adeF1eTDfj46f0OWcv+cvru6eAAAA
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708683020; l=785;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=rj50khMCd7O7B7v0SRHISMJug9v3bULtlYjPZBTU/UE=;
 b=KVFzD4/LxaLBN4mijJPpCUdHSXjWF4tITatM8znI+xJq8WdzSibMB92wnRHDyb/bBv2YGJpUw
 7KKvEfT0H5QAP7il7TzxQolRaKUegsfGybEbzOPsbYC/lKe0Nw0Cc6Y
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

simple power-managed buses can also have resets. Get and deassert them
if possible.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- use wrapper
- Link to v1: https://lore.kernel.org/r/20240223-b4-bus-v1-0-2803c3ac4673@outlook.com

---
Yang Xiwen (2):
      dt-bindings: simple-pm-bus: Add optional resets
      drivers: bus: simple-pm-bus: Get and deassert resets exclusively

 Documentation/devicetree/bindings/bus/simple-pm-bus.yaml |  7 +++++--
 drivers/bus/simple-pm-bus.c                              | 16 ++++++++++++++--
 2 files changed, 19 insertions(+), 4 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240223-b4-bus-d5c6f75a251a

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

