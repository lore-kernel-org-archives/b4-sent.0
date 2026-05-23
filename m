From: Demi Marie Obenour <demiobenour@gmail.com>
Date: Sat, 23 May 2026 15:43:04 -0400
Subject: [PATCH 3/3] AF_ALG: Document that it is *always* slower
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260523-af-alg-harden-v1-3-c76755c3a5c5@gmail.com>
References: <20260523-af-alg-harden-v1-0-c76755c3a5c5@gmail.com>
In-Reply-To: <20260523-af-alg-harden-v1-0-c76755c3a5c5@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779565388; l=2773;
 i=demiobenour@gmail.com; s=20250731; h=from:subject:message-id;
 bh=cCZclUN91iyFrsr3PZ6oslmjWDYG7uvJ1BorPBKSILk=;
 b=tMvuqZQCtqZsAaMqHEV39cBc/++4hmxFbFBMdRmtHQtjclb/Ws8rPWSMTsw9+kwtC7mX2BxyO
 lWvyv8MjokkBQ9W7YuISmmpzpSoOKpUxcuzWE1mfMgEZmwyHZtvfm6N
X-Developer-Key: i=demiobenour@gmail.com; a=ed25519;
 pk=4iGY+ynEKxIfs+fIUK9EzsvZ44yGE0GvXLeLTPKKPhI=
X-Endpoint-Received: by B4 Relay for demiobenour@gmail.com/20250731 with auth_id=473
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without support for zero-copy or off-CPU offloads, AF_ALG is always
slower than software cryptography. Its only advantage is that it might
save code size. However, this is largely mitigated by lightweight
userspace cryptographic libraries.

Signed-off-by: Demi Marie Obenour <demiobenour@gmail.com>
---
 Documentation/crypto/userspace-if.rst | 19 +++++++++++++++++--
 1 file changed, 17 insertions(+), 2 deletions(-)

diff --git a/Documentation/crypto/userspace-if.rst b/Documentation/crypto/userspace-if.rst
index b31117d4415dda6ad6ca36275e615bec7df9552e..ab93300c8e04524469f284704c7c5ed582fdcbc0 100644
--- a/Documentation/crypto/userspace-if.rst
+++ b/Documentation/crypto/userspace-if.rst
@@ -28,8 +28,8 @@ functionality than that. It actually provides access to all software algorithms.
 
 This includes arbitrary compositions of different algorithms created via a
 complex template system, as well as algorithms that only make sense as internal
-implementation details of other algorithms. It also includes full zero-copy
-support, which is difficult for the kernel to implement securely.
+implementation details of other algorithms. In the past, it also included full
+zero-copy support, which was difficult for the kernel to implement securely.
 
 Ultimately, these algorithms are just math computations. They use the same
 instructions that userspace programs already have access to, just accessed in a
@@ -38,6 +38,21 @@ much more convoluted and less efficient way.
 Indeed, userspace code is nearly always what is being used anyway. These same
 algorithms are widely implemented in userspace crypto libraries.
 
+Even when zero-copy and off-CPU accelerators were supported, AF_ALG was usually
+much slower than optimized software cryptography in userspace. This was
+especially true for the small message sizes usually seen in performance-critical
+workloads. While it was possible to demonstrate performance wins for hashing
+large files on embedded devices, it is hard to imagine a situation where this
+would be performance-critical.
+
+Nowadays, AF_ALG no longer supports zero-copy or off-CPU accelerators.
+Therefore, it is *always* slower than an optimized userspace implementation,
+even for large messages. The only possible advantage left is that it avoids
+duplicating code between kernel and userspace. However, userspace
+implementations, especially hardware-accelerated ones, do not need to be large.
+Just because OpenSSL is huge does not mean that all userspace cryptography
+libraries are.
+
 Meanwhile, AF_ALG hasn't been withstanding modern vulnerability discovery tools
 such as syzbot and large language models. It receives a steady stream of CVEs.
 Some of the examples include:

-- 
2.54.0

