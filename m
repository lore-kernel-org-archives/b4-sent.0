From: David Crawshaw <david@exe.dev>
Subject: [PATCH 0/2] fuse: fix data loss when writeback races a
 write-through extending write
Date: Fri, 27 Nov 2026 04:08:38 +0000
Message-Id: <20261127-b4-fuse-wt-eof-v1-0-e055e2af652d@exe.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEYCCWsC/yXMQQ6CMBBG4auQWTuJrdiKVzEuKP7VcQGkA2rSc
 HcKLr/Fe5kUSaB0rTIlfERl6AvMoaLu1fZPsDyKyR6tM8Z6DjXHWcHfiTFE9sGb2jWX8ymASjQ
 mRPntw9v9b53DG920XWhZVk8a8N1yAAAA
X-Change-ID: 20261127-b4-fuse-wt-eof-7b71469853be
To: Miklos Szeredi <miklos@szeredi.hu>, 
 "Darrick J. Wong" <djwong@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 Joanne Koong <joannelkoong@gmail.com>, Shuah Khan <shuah@kernel.org>
Cc: fuse-devel@lists.linux.dev, linux-kselftest@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, regressions@lists.linux.dev, 
 David Crawshaw <david@exe.dev>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795752531; l=1976;
 i=david@exe.dev; s=20261127; h=from:subject:message-id;
 bh=/uZwlpKJlvGvr6lTGIgh3p40tIbnOtPhD5Kl6WqbtuQ=;
 b=+7IrrOKCwsFl/f8JAosPywwOryhD5UclQsoKBCSUXZ4rKvgiQraL0C6ykQ4RX58RHmueH3z8e
 CqpLN5xraBTDsm+mvL5eAd+qJQdgfKBO6yqS8Mttj0rhY8y52FW3FR8
X-Developer-Key: i=david@exe.dev; a=ed25519;
 pk=eQfKiR9S2peqiHuuNGCAaWlxwP+RerhKT2wVxakCrjQ=
X-Endpoint-Received: by B4 Relay for david@exe.dev/20261127 with auth_id=1661
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since v6.17 commit ef7e7cbb323f "fuse: use iomap for writeback",
a write-through pwrite() that extends a file inside the folio
holding EOF can return success and lose its data. This happens
when that folio is dirty and writeback of it starts while the
FUSE_WRITE is in flight.

The mechanism is that fuse_perform_write() unlocks the folio before
sending the request and only updates i_size after the reply, and
iomap_writeback_handle_eof() zeroes the folio beyond the old i_size.

Patch 1 keeps a folio that straddles i_size locked over the request
when the write extends the file within it, and updates i_size before
the folios are unlocked, like iomap_write_iter() does.

Patch 2 adds a deterministic selftest case.

Reproduced on v6.17 and v7.4-rc4+ (9437ee8b6cf9); not on v6.16.

Data lost in the reproducer:

                                   unpatched        patched
  WRITE delayed 200us/0/2ms        1428/1500        0/6000
  8 mounts in parallel             3229/4000        0/4000
  EOF in a large folio (THP)        811/900         0/900
  new selftest case                 50/50 fail      50/50 pass

(All testing done on x86_64 KVM guests.)

Disclosure: the bisection, and both patches were produced by an AI
coding agent (exe.dev's Shelley, using the Opus 5.5 model).
I reviewed the work and wrote the bulk of the prose.

Signed-off-by: David Crawshaw <david@exe.dev>
---
David Crawshaw (2):
      fuse: update i_size before unlocking the EOF folio in write-through writes
      selftests/fuse: test a write extending the file beside writeback of the EOF page

 fs/fuse/file.c                                     | 21 ++++++-
 .../filesystems/fuse/write_extend_eof_test.c       | 71 ++++++++++++++++++++++
 2 files changed, 91 insertions(+), 1 deletion(-)
---
base-commit: 9437ee8b6cf607e883b36e44bd755968daaebd48
change-id: 20261127-b4-fuse-wt-eof-7b71469853be

Best regards,
--  
David Crawshaw <david@exe.dev>

