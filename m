From: =?utf-8?q?Dawid_Wro=CC=81bel?= <me@dawidwrobel.com>
Subject: [PATCH 0/2] ASoC: codecs: lpass-{tx,wsa}-macro: fix enum kcontrol
 accesses
Date: Wed, 29 Jul 2026 21:38:11 +0200
Message-Id: <20260729-worktree-lpass-tx-macro-enum-fix-v1-0-0cf02c681332@dawidwrobel.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2NwQqDMBAFf0X27IINqNhfKR5i+tIu1kR2bSuI/
 97Q48xh5iCDCoyu1UGKj5jkVOBSVxSePj3Aci9MrnFd07uBv1nnTQF+rd6Mt50XHzQz0nvhKDu
 HNk4+Ivbt1FHJrIqi/4vbeJ4/K1E/ynIAAAA=
X-Change-ID: 20260729-worktree-lpass-tx-macro-enum-fix-c5fbafef75b6
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Dawid_Wro=CC=81bel?= <me@dawidwrobel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1083; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=jsMXZT4gccjDa/7ErbHIlfifUX0YqbHsZ0/8RwqBSAE=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWRlha1nS6p4uetNRXn3lj2mLXef7f3AlXv6pFaZpWH8M
 mmhZZKNHaUsDGJcDLJiiix6aUF7rIJffn/34nc4zBxWJpAhDFycAjCRXRsZGbrKl8v6bXn1av25
 /67Xrkit/Fsp9C+L9/GluJhjezyfxLxjZLi09bby5c8yP+ZtUpE+OmX7tdsfV61ZmMf868V9RQ+
 Vn7XsAA==
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
Dawid Wróbel (2):
      ASoC: codecs: lpass-tx-macro: Fix enum kcontrol accesses
      ASoC: codecs: lpass-wsa-macro: Fix enum kcontrol accesses

 sound/soc/codecs/lpass-tx-macro.c  | 4 ++--
 sound/soc/codecs/lpass-wsa-macro.c | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)
---
base-commit: 57b8e2d666a31fa201432d58f5fe3469a0dd83ba
change-id: 20260729-worktree-lpass-tx-macro-enum-fix-c5fbafef75b6

Best regards,
-- 
Dawid Wróbel <me@dawidwrobel.com>

