From: =?utf-8?q?Dawid_Wro=CC=81bel?= <me@dawidwrobel.com>
Subject: [PATCH v2 0/2] ASoC: codecs: lpass-{tx,wsa}-macro: fix enum
 kcontrol accesses
Date: Thu, 30 Jul 2026 12:58:11 +0200
Message-Id: <20260730-worktree-lpass-tx-macro-enum-fix-v2-0-6d091c736116@dawidwrobel.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/5WNQQ6CMBAAv0L27JpSAqgn/2E4lLKVjUDJFgFD+
 LuVH3icOcxsEEiYAtySDYRmDuyHCPqUgG3N8CTkJjJopQtV6isuXl6TEGE3mhBwWrE3VjzS8O7
 R8Yo2d7Vx5Mq8LiBmRqGoj8WjitxymLx8juOc/uwf8TlFhco6pW1xSbNM3xuzcLOIr6k7W99Dt
 e/7F8ajQmDWAAAA
X-Change-ID: 20260729-worktree-lpass-tx-macro-enum-fix-c5fbafef75b6
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Dawid_Wro=CC=81bel?= <me@dawidwrobel.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1401; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=IN4Ms0Tw3dH/UmsG7qdrz04onb6Mc5bbMOV5N5b8x6k=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWRl64VMNku2SipeMPdR9/KHEQ1x8QonTvtEft7puX+pR
 6RW+YcLHaUsDGJcDLJiiix6aUF7rIJffn/34nc4zBxWJpAhDFycAjARW09GhtbSMtNr3Md49A0X
 Mkw8mDFhp72VpM2x5rcnG9pnWvWeV2VkWG/yVy8vNawy6fjvxx/EjG/cytyR87xi86Y50ctnOIa
 fZAcA
X-Developer-Key: i=me@dawidwrobel.com; a=openpgp;
 fpr=B64A778E0E64049A70C831C8B7B81FA12B282A92
X-Endpoint-Received: by B4 Relay for me@dawidwrobel.com/default with auth_id=901
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both drivers access enumerated controls through value.integer.value[0]
instead of value.enumerated.item[0]. The same bug was fixed in rx-macro
and va-macro in 2022 (bcfe5f76cc40, 0ea5eff7c606); tx-macro and
wsa-macro were missed.

On 64-bit kernels with CONFIG_SND_CTL_DEBUG this trips the elem value
sanity check, and every read of the affected controls fails with
-EINVAL.

Reproduced and fixed on a Xiaomi Mi Pad 5 Pro (SM8250) for tx-macro.
wsa-macro is compile-tested only — that codec is not instantiated on
this hardware.

Signed-off-by: Dawid Wróbel <me@dawidwrobel.com>
---
Changes in v2:
- wsa-macro: also fix wsa_macro_rx_mux_get() and wsa_macro_rx_mux_put(),
  which have the same bug (Srinivas Kandagatla)
- Cc stable on both patches (Srinivas Kandagatla)
- Link to v1: https://lore.kernel.org/r/20260729-worktree-lpass-tx-macro-enum-fix-v1-0-0cf02c681332@dawidwrobel.com

---
Dawid Wróbel (2):
      ASoC: codecs: lpass-tx-macro: Fix enum kcontrol accesses
      ASoC: codecs: lpass-wsa-macro: Fix enum kcontrol accesses

 sound/soc/codecs/lpass-tx-macro.c  | 4 ++--
 sound/soc/codecs/lpass-wsa-macro.c | 8 ++++----
 2 files changed, 6 insertions(+), 6 deletions(-)
---
base-commit: 57b8e2d666a31fa201432d58f5fe3469a0dd83ba
change-id: 20260729-worktree-lpass-tx-macro-enum-fix-c5fbafef75b6

Best regards,
-- 
Dawid Wróbel <me@dawidwrobel.com>

