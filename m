From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH 0/3] powerpc/pseries/memhp: Fix minor bugs and improve
 error logging
Date: Tue, 14 Nov 2023 11:01:52 -0600
Message-Id: <20231114-pseries-memhp-fixes-v1-0-fb8f2bb7c557@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAACoU2UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2NDQ0MT3QKIBt3c1NyMAt20zAog29DC1NLCIiUl1SjRQAmos6AoFSwB1Bg
 dW1sLAIjdJyxlAAAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: Nick Child <nnac123@linux.ibm.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@linux.ibm.com>, 
 Scott Cheloha <cheloha@linux.ibm.com>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699981353; l=644;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=zdbILnLJ8Bse+F5hjFg/R9HPGLYwSKFm8c754/A0PGM=;
 b=6iG3yJoacYElVhp7oJuqIzdI2jyjd84ec391zC88z3nIqOPYe3GikpSgyb9BCW50ISrB4d0pH
 3bZy/oPmZ5/B30YXtCCF2z5pQ/CDftqxpXWG7WUJQEB/GxSSpWwRY25
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This includes a fix for an array bounds read overrun that can be
triggered when debug messages are enabled.

---
Nathan Lynch (3):
      powerpc/pseries/memhp: Fix access beyond end of drmem array
      powerpc/pseries/memhp: Remove unbalanced dlpar_release_drc() call
      powerpc/pseries/memhp: Log more error conditions in add path

 arch/powerpc/platforms/pseries/hotplug-memory.c | 17 +++++++++++------
 1 file changed, 11 insertions(+), 6 deletions(-)
---
base-commit: 707df298cbde200b939c70be2577b20775fe3345
change-id: 20231114-pseries-memhp-fixes-185988dde2a0

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

