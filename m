From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH v2 0/2] dpll: zl3073x: add Microchip ZL30643 support
Date: Thu, 30 Jul 2026 19:35:34 +0200
Message-Id: <20260730-for-upstream-zl30643-v2-0-0ea0bbd03755@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGaLa2oC/4WNQQ6CMBBFr0Jm7ZjS1gKuvIdh0cJUmiiQKTYq4
 e5WLuDyveS/v0IkDhThXKzAlEIM05hBHgroBjveCEOfGaSQRlRSo58Yn3NcmOwDP3cljFZYO6m
 kqVxTaQ95OjP58Nqz1zbzEOIy8Xt/SeXP/gmmEgWSbZSzuq9PXX3xTHT0DO22bV/OVpG0tgAAA
 A==
To: Ivan Vecera <ivecera@redhat.com>, 
 Prathosh Satish <Prathosh.Satish@microchip.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vadim Fedorenko <vadim.fedorenko@linux.dev>, 
 Arkadiusz Kubalewski <arkadiusz.kubalewski@intel.com>, 
 Jiri Pirko <jiri@resnulli.us>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785432952; l=1540;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=6AKWLtGif7r+vr72wU4kwdqfkXx5/kNLwiBtRyPgSQk=;
 b=KPaiveD14ie456lg8mc4KK4inmbmJuzjR6fdxEdOvHIMUzTg/Y02mK50rNLH8MFnblKbfvoAM
 p/3eNgF2IPNAp91X77FGA0RhkkJLLM6bLOqCCu1YojWzp0ZniWl4E25
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Microchip ZL30643 (chip ID 0x0E3B) is a 3 DPLL channel member of
the ZL3064x timing family, register compatible with the
ZL30733 of the ZL3073x family.

Patch 1 describes it in the binding as a fallback to the register-
        equivalent microchip,zl30733.
Patch 2 adds the 0x0E3B runtime chip-ID table entry; no new match
        strings, the fallback binds via the existing microchip,zl30733
        entry.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v2:
- bindings: describe ZL30643 as a fallback to the ZL30733 instead of a
  standalone compatible (based on Conor's questions).
- driver: drop the SPI/I2C/of_match additions: the fallback binds via
  microchip,zl30733; keep only the 0x0E3B chip-ID table entry needed
  for the runtime channel-count lookup.
- commit messages: comments on the datasheets and identity backing
  the REF_PHASE_COMP_32 flag reuse (Ivan's questions).
- Link to v1: https://lore.kernel.org/r/20260724-for-upstream-zl30643-v1-0-ea93ba4d85c8@free.fr

---
Vincent Jardin (2):
      dt-bindings: dpll: zl3073x: ZL30643 is compatible
      dpll: zl3073x: recognize the ZL30643 chip ID (0x0E3B)

 .../devicetree/bindings/dpll/microchip,zl30731.yaml   | 19 +++++++++++++------
 drivers/dpll/zl3073x/core.c                           |  1 +
 2 files changed, 14 insertions(+), 6 deletions(-)
---
base-commit: 248951ddc14de84de3910f9b13f51491a8cd91df
change-id: 20260724-for-upstream-zl30643-8b23267b974f

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

