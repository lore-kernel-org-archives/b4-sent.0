From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:32:00 +0100
Subject: [PATCH 19/19] MAINTAINERS: Add entry for LANCOM board support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-19-86f78ba2a7af@posteo.net>
References: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
In-Reply-To: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Frank Li <Frank.Li@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=747;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=dAH39hTNAFd2Gn5pb9BXoNF53Untzct7/Ny6B9T7rmc=;
 b=JbUR+WMaOFgpoRGjfGRqrBOPDgnsyxY7Nup2gMAnp2r3UNMzcEwns5pKruLl7F84UyqvM5QId
 sJbADWCBw83DtJgSJAT7pJj+IAa5Cq7WldU6YJFkVO7S4qLA7JrKVnw
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Provide a contact for NWAPP2 and other boards.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 910305c11e8a882da5b49ce5bd55011b93f28c32..6d4717cf7c19c25aa50c5cf1a7956797225a1d21 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -12951,6 +12951,14 @@ S:	Maintained
 F:	include/net/l3mdev.h
 F:	net/l3mdev
 
+LANCOM BOARD SUPPORT
+M:	J. Neuschäfer <j.ne@posteo.net>
+L:	linuxppc-dev@lists.ozlabs.org
+F:	arch/powerpc/boot/dts/lancom-*.dts
+F:	arch/powerpc/boot/dts/mpc831*
+K:	lancom
+K:	LANCOM
+
 LANDLOCK SECURITY MODULE
 M:	Mickaël Salaün <mic@digikod.net>
 R:	Günther Noack <gnoack@google.com>

-- 
2.45.2

