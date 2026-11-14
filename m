From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] crypto: ecc - Fix P-521 public key generation
Date: Sat, 14 Nov 2026 08:44:12 +0000
Message-Id: <20261114-ecc-p521-small-scalars-v1-0-7b114f076b33@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORtoio7iq4iHNo0uo26jURHG3
 t06j9/h/1cwqSoG526FKm81nacGOnTAQ5zugpqbwTvfE9ERhRmXkye0RywFjWOJ1bB3lHMIjkN
 K0OKlyk0/+/hy/dteaRR+/m6wbV99o+HEegAAAA==
X-Change-ID: 20261114-ecc-p521-small-scalars-601dd880c8bb
To: Lukas Wunner <lukas@wunner.de>, Ignat Korchagin <ignat@linux.win>, 
 Stefan Berger <stefanb@linux.ibm.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, 
 Jarkko Sakkinen <jarkko@kernel.org>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Erwin Pawliczek <pawliczekerwin@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794645852; l=918;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=s/LhpwHvt85EydqWoJFpNYvfgoCBmP/uoS1ROXm5kcc=;
 b=lJW3yZ+EzBLCAxAaFW+n4QfoqajhwxxjfNDyRbxDH52TVcvIsagGMvsHBVjiTQYeHgusT/Cke
 cV8blHRizvZB+ftFvqsLdFcQjaPbOz0wD2NXEPBtSjuFNTFsHiZPEMa
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two P-521 fixes for crypto/ecc.c. Patch 1 keeps the random initial Z
from commit cd65eaf17841 below 2^521: with 576 bits, every P-521
ecc_make_pub_key() call fails with -EAGAIN. Patch 2 fixes the scalar
multiplication for scalars below about 2^259.5. No in-tree caller is
affected yet.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages. I reviewed it and tested it
as described in each patch.

---
Arun Iyengar (2):
      crypto: ecc - Keep the random initial Z below 2^521 on P-521
      crypto: ecc - Fix P-521 scalar multiplication for small scalars

 crypto/ecc.c | 31 +++++++++++++++++++------------
 1 file changed, 19 insertions(+), 12 deletions(-)
---
base-commit: 8ba9044ff0bf4a5789216496019fad614eeafd45
change-id: 20261114-ecc-p521-small-scalars-601dd880c8bb

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

