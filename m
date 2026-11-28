From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/3] crypto: ecc - Fix P-521 public key generation
Date: Sat, 28 Nov 2026 17:38:27 +0000
Message-Id: <20261128-ecc-p521-small-scalars-v2-0-0648f492bca4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7Zi2KBBX3sOwaIcCNYWSDhIN4
 e4WPIDLl7z//gpso7MMt2yFaBfHLowJ1CkD6vXYWXRNYlBCFVLKC1oinK5KIg/ae2TSXkfGQsi
 mqSpBlTGQxlO0rXsf4Uf9Y36Zp6V5r+1G73gO8XM8L3L3/p4sEgWWJhmtKAuT5/du0M6fKQxQb
 9v2Bf76RWHOAAAA
X-Change-ID: 20261114-ecc-p521-small-scalars-601dd880c8bb
To: Lukas Wunner <lukas@wunner.de>, Ignat Korchagin <ignat@linux.win>, 
 Stefan Berger <stefanb@linux.ibm.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, 
 Jarkko Sakkinen <jarkko@kernel.org>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Erwin Pawliczek <pawliczekerwin@gmail.com>, 
 Laveesh Bansal <laveeshb@laveeshbansal.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887508; l=1493;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=4QpzPaJjDpMKCRNZSFtiQ93lkyKG0Q3bS0kfTB4aQN4=;
 b=VFcL6HPjxSwGe5+T1DESuutSYUnD7Ll+XRHx9ZAgIWks2Db2gRzlMEdedkNJ/xnbfu8rH2zWQ
 nsfGmnvgGVIC2QlbeFkAXn88wev2H+YExsqC9e+LwjbVdRg68PtFuYw
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two P-521 fixes for crypto/ecc.c and a KUnit test. Patch 1 keeps the
random initial Z from commit cd65eaf17841 below 2^521: with 576 bits,
every P-521 ecc_make_pub_key() call fails with -EAGAIN. Patch 2 fixes
the scalar multiplication for scalars below about 2^259.5. Patch 3,
suggested by Laveesh Bansal, tests P-521 key generation. No in-tree
caller is affected yet.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages. I reviewed it and tested it
as described in each patch.

---
Changes in v2:
- Add Tested-by from Laveesh Bansal to patches 1 and 2.
- Patch 2: note that k = n now runs the ladder on 2n.
- New patch 3: KUnit test for P-521 key generation.
- Link to v1: https://patch.msgid.link/20261114-ecc-p521-small-scalars-v1-0-7b114f076b33@gmail.com

---
Arun Iyengar (3):
      crypto: ecc - Keep the random initial Z below 2^521 on P-521
      crypto: ecc - Fix P-521 scalar multiplication for small scalars
      crypto: ecc - Add KUnit test for P-521 public key generation

 crypto/Kconfig    | 11 +++++++
 crypto/Makefile   |  1 +
 crypto/ecc.c      | 31 +++++++++++-------
 crypto/ecc_test.c | 94 +++++++++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 125 insertions(+), 12 deletions(-)
---
base-commit: 9fb9278d13dca54ce7ecd3254c7df8839e59f03d
change-id: 20261114-ecc-p521-small-scalars-601dd880c8bb

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

