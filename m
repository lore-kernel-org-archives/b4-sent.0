From: Demi Marie Obenour <demiobenour@gmail.com>
Subject: [PATCH 0/3] AF_ALG: Remove support for AIO and old-style drivers
Date: Sat, 23 May 2026 15:43:01 -0400
Message-Id: <20260523-af-alg-harden-v1-0-c76755c3a5c5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUwMj3cQ03cScdN2MxKKU1DxdSwMDCxNLE1NDM1NjJaCegqLUtMwKsHn
 RsbW1AAl0ZOpfAAAA
X-Change-ID: 20260502-af-alg-harden-900849451653
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Kuniyuki Iwashima <kuniyu@google.com>, Paolo Abeni <pabeni@redhat.com>, 
 Willem de Bruijn <willemb@google.com>, Jens Axboe <axboe@kernel.dk>, 
 Jakub Kicinski <kuba@kernel.org>, Simon Horman <horms@kernel.org>, 
 Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Eric Biggers <ebiggers@google.com>, 
 Ard Biesheuvel <ardb@kernel.org>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 io-uring@vger.kernel.org, netdev@vger.kernel.org, 
 linux-perf-users@vger.kernel.org, linux-doc@vger.kernel.org, 
 Demi Marie Obenour <demiobenour@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779565388; l=1545;
 i=demiobenour@gmail.com; s=20250731; h=from:subject:message-id;
 bh=D3zxq48jpNb8NeX8OBIi5fswzSbQEgmlY+KRsUrVG/o=;
 b=UWO/qocMd43s589G/tauUvyAgol1bxSgtpx423ChGfzN9f//3VW16eJhzkctofOPU6zoYSfaG
 lOI3O1+/rnwA0dZf4yBziamZeyECAINgeTNroGcSZIlvhNlXeYFNVWc
X-Developer-Key: i=demiobenour@gmail.com; a=ed25519;
 pk=4iGY+ynEKxIfs+fIUK9EzsvZ44yGE0GvXLeLTPKKPhI=
X-Endpoint-Received: by B4 Relay for demiobenour@gmail.com/20250731 with auth_id=473
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

AF_ALG is a deprecated API only useful for compatibility with existing
userspace.  It has had a lot of vulnerabilities, including the infamous
CopyFail.

Rip out support for offload drivers, which tend to be buggy.  Also rip
out support for AIO, which actually bloats the entire socket subsystem.

Only compile-tested.

Signed-off-by: Demi Marie Obenour <demiobenour@gmail.com>
---
Demi Marie Obenour (3):
      net: Remove support for AIO on sockets
      AF_ALG: Drop support for off-CPU cryptography
      AF_ALG: Document that it is *always* slower

 Documentation/crypto/userspace-if.rst          | 26 ++++++++--
 crypto/af_alg.c                                | 35 ++------------
 crypto/algif_aead.c                            | 43 ++++-------------
 crypto/algif_hash.c                            |  4 +-
 crypto/algif_rng.c                             |  4 +-
 crypto/algif_skcipher.c                        | 66 ++++++--------------------
 include/crypto/if_alg.h                        | 19 ++++++--
 include/linux/socket.h                         |  1 -
 io_uring/net.c                                 |  1 -
 net/compat.c                                   |  1 -
 net/socket.c                                   |  7 +--
 tools/perf/trace/beauty/include/linux/socket.h |  1 -
 12 files changed, 70 insertions(+), 138 deletions(-)
---
base-commit: 49e05bb00f2e8168695f7af4d694c39e1423e8a2
change-id: 20260502-af-alg-harden-900849451653

Best regards,
-- 
Demi Marie Obenour <demiobenour@gmail.com>

