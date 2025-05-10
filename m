From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 10 May 2025 07:44:42 +0000
Subject: [PATCH 2/7] nvmem: core: round up to word_size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250510-nvmem-dt-v1-2-eccfa6e33f6a@svenpeter.dev>
References: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
In-Reply-To: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
To: Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1011; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=H4fL+CAaJi5RsVSWx0aHxTvxkzr7MJNevpfVzdnrUaE=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4Y8879pU0vbs4VO/5ijucvz2QEJ3lUxMZOLLk9YufX/+
 XpJM/+nHaUsDGIcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJ/NRj+F/vJXd5iYrr0s4d
 M34U/TTJDHolWdu+20GUVeDk/stvgr4x/A+5W/zSJJ9N6c8Etdg/UqW8ebnKszftrHz0/Up8hcZ
 HGwYA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some nvmem controllers like Apple's eFuses or Nintendo's OTP have a cell
word size that's larger than one byte and cannot read anything smaller.
Round up cell->bytes correctly when accessing a subset of bits.

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/nvmem/core.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/nvmem/core.c b/drivers/nvmem/core.c
index 1bd39b12c21a86b9b135be95251a52a10543c2ea..02081c93fa467e5448bd78a4920072d437365fb9 100644
--- a/drivers/nvmem/core.c
+++ b/drivers/nvmem/core.c
@@ -595,8 +595,8 @@ static int nvmem_cell_info_to_nvmem_cell_entry_nodup(struct nvmem_device *nvmem,
 	cell->np = info->np;
 
 	if (cell->nbits)
-		cell->bytes = DIV_ROUND_UP(cell->nbits + cell->bit_offset,
-					   BITS_PER_BYTE);
+		cell->bytes = round_up(DIV_ROUND_UP(cell->nbits + cell->bit_offset,
+					   BITS_PER_BYTE), nvmem->word_size);
 
 	if (!IS_ALIGNED(cell->offset, nvmem->stride)) {
 		dev_err(&nvmem->dev,

-- 
2.34.1

