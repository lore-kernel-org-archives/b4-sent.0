From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/3] PowerPC/Wii: A few devicetree cleanups
Date: Wed, 11 Mar 2026 18:35:55 +0100
Message-Id: <20260311-wii-schema-v1-0-1563ac4aefa8@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPunsWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY0ND3fLMTN3i5IzU3ERdkyQTg2Rz8zSLZMtEJaCGgqLUtMwKsGHRsbW
 1AN6YVydcAAAA
X-Change-ID: 20260311-wii-schema-4b40c77f8c9a
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Link Mauve <linkmauve@linkmauve.fr>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773250574; l=575;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=xjKTDTd8ojlA8FfIUmj0qcyQ4/gIsPJELfOQhU0E5aQ=;
 b=zhOibk57Sy5roTUBK9nE4MIkOyWyEqD34XxRVVNfbYQWWc+tDK26S9c1UQSMK+MxO+zpyAUb9
 7UVSXf+7ErzDw7eZ57HKw/M1HVBeW+/0UfquAISraqRVWUdU/ae8n5x
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series contains a few minor fixes to make wii.dts somewhat more
compliant with the DT schemas.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (3):
      powerpc: wii: Add unit address to /memory
      powerpc: wii: Fix GPIO key name pattern
      powerpc: wii: Fix LED name pattern

 arch/powerpc/boot/dts/wii.dts | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)
---
base-commit: 6af06d984685645b4f80132a8defb09747b10989
change-id: 20260311-wii-schema-4b40c77f8c9a

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

