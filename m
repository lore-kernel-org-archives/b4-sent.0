From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/4] powerpc: Rename wdt@ notes to watchdog@
Date: Fri, 18 Apr 2025 21:28:50 +0200
Message-Id: <20250418-watchdog-v1-0-987ff2046272@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPKnAmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0ML3fLEkuSMlPx03ZRkY1MDw6Q0S8OUFCWg8oKi1LTMCrBR0bG1tQA
 7nU6yWgAAAA==
X-Change-ID: 20250418-watchdog-dc3501bf91dd
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745004545; l=1502;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=HKi4/pkN8/8Z6aYIPs2g1TUo9vd+kfLsVo0FqhGriIg=;
 b=NDbbrgw8AjbiooyxPiw4H0nG7A6qJKUbMqvcm1w/C9ntxHUrx41SqIjUsaFelMOBtmYb/HuVY
 W8vmyo8ZfS8B6VwXTkaz7HltxUvh2B3spCh1SMMkvA7YJrbwKDqRg8u
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The watchdog.yaml schema prescribes a node name of "timer" or "watchdog"
rather than the abbreviation "wdt". This series fixes the node name
across arch/powerpc/boot/dts.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (4):
      powerpc: 512x: Rename wdt@ node to watchdog@
      powerpc: 83xx: Rename wdt@ nodes to watchdog@
      powerpc: 86xx: Rename wdt@ nodes to watchdog@
      powerpc: p2020: Rename wdt@ nodes to watchdog@

 arch/powerpc/boot/dts/asp834x-redboot.dts | 2 +-
 arch/powerpc/boot/dts/fsl/ge_imp3a.dts    | 4 ++--
 arch/powerpc/boot/dts/fsl/gef_ppc9a.dts   | 4 ++--
 arch/powerpc/boot/dts/fsl/gef_sbc310.dts  | 4 ++--
 arch/powerpc/boot/dts/fsl/gef_sbc610.dts  | 4 ++--
 arch/powerpc/boot/dts/mpc5121.dtsi        | 2 +-
 arch/powerpc/boot/dts/mpc8313erdb.dts     | 2 +-
 arch/powerpc/boot/dts/mpc8315erdb.dts     | 2 +-
 arch/powerpc/boot/dts/mpc832x_rdb.dts     | 2 +-
 arch/powerpc/boot/dts/mpc8349emitx.dts    | 2 +-
 arch/powerpc/boot/dts/mpc8349emitxgp.dts  | 2 +-
 arch/powerpc/boot/dts/mpc836x_rdk.dts     | 2 +-
 arch/powerpc/boot/dts/mpc8377_rdb.dts     | 2 +-
 arch/powerpc/boot/dts/mpc8377_wlan.dts    | 2 +-
 arch/powerpc/boot/dts/mpc8378_rdb.dts     | 2 +-
 arch/powerpc/boot/dts/mpc8379_rdb.dts     | 2 +-
 16 files changed, 20 insertions(+), 20 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250418-watchdog-dc3501bf91dd

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

