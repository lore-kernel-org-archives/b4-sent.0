From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/2] Add missing model properties to PowerPC DTs
Date: Fri, 13 Mar 2026 11:14:22 +0100
Message-Id: <20260313-ppc-model-v1-0-bf19b3d1b65d@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAH7js2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQwNj3YKCZN3c/JTUHF1zUwNTY3OLJEsLS2MloPqCotS0zAqwWdGxtbU
 AL1hY3lsAAAA=
X-Change-ID: 20260103-ppc-model-7505378b9893
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773396881; l=1021;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Kf6XOEnYm2GvG4lKYi0o2kULPxTSxS+f7wvZBuUn3qQ=;
 b=KR6jIkoaxRRvaO5H3NOKWTIZDnjVVcw5alUG/E6A+QYykmdXiuqYmjGMGm67s0m6z8dNfL+zI
 K4Mx3SvUePHAb20hXi6kVl5kuVpjjL7UiiBDmsK+6H8I1U1SRyG9Eq3
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The devicetree spec requires a /model property, but many of the powerpc
devicetrees don't have one. This series is an attempt to fix it.

One practical advantage is that scripts/make_fit.py will no longer throw
an error when invoked with the powerpc DTs.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (2):
      powerpc: dts: mpc8315erdb: Add missing model property
      powerpc: dts: Add missing model properties

 arch/powerpc/boot/dts/mpc8308_p1m.dts  | 1 +
 arch/powerpc/boot/dts/mpc8308rdb.dts   | 1 +
 arch/powerpc/boot/dts/mpc8315erdb.dts  | 1 +
 arch/powerpc/boot/dts/mpc836x_rdk.dts  | 1 +
 arch/powerpc/boot/dts/mpc8377_rdb.dts  | 1 +
 arch/powerpc/boot/dts/mpc8377_wlan.dts | 1 +
 arch/powerpc/boot/dts/mpc8378_rdb.dts  | 1 +
 arch/powerpc/boot/dts/mpc8379_rdb.dts  | 1 +
 8 files changed, 8 insertions(+)
---
base-commit: c9849854bc5ce9afca21f97bb17b7ff763fdf159
change-id: 20260103-ppc-model-7505378b9893

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

