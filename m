From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH 0/4] selinux: make declared counts account for the values
Date: Fri, 31 Jul 2026 12:44:08 -0500
Message-Id: <20260731-b4-disp-d32e997b-v1-0-0341d038ee47@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz7XkhD/BVSoGkhhwB0AxICTE3
 Unb8Rveu0A5Ciu02QWRD1FZ5gTzysBP/TwySkgGS7aiOjfoCgyiK4bcctPUDj2RZe9MWVAJKVs
 jD3L+lu/ub93dh/32/cB9P4rY49Z0AAAA
X-Change-ID: 20260731-b4-disp-d32e997b-c002ecb15405
To: Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>
Cc: linux-kernel@vger.kernel.org, Ondrej Mosnacek <omosnace@redhat.com>, 
 Kees Cook <kees@kernel.org>, selinux@vger.kernel.org, 
 =?utf-8?q?Christian_G=C3=B6ttsche?= <cgzones@googlemail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785519848; l=5998;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=0MzpL5lmGqP9qsSiOAUrftQ+v6PfBDDK6GoC2AfslY0=;
 b=CwCb33z1lKnN07Rv3C3CB37OMolpuWMWGdnSMW6BvsKvxwGpjSTqAsgSDsBUezAUMH8mF/HOV
 nlGJH0QTjRrB7VK9LjnARlZKXl+ep1KGZKLRWNqjWc/+js9yd88ncIH
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The two patches just merged [1] bound each permission value by the count
that sizes the array it indexes. That is half of what those arrays need:
they are filled by value, so every slot also has to be claimed, and claimed
once. 2/4 closes both halves for the permission array. 3/4 and 4/4 do the
same one layer up, for the class and boolean arrays, which have the same
shape and are reached from the same policy load. 1/4 is a prerequisite --
the error path 3/4 newly makes reachable already has a NULL dereference in
it.

A count check is not enough for 2/4, which is worth saying because it is the
obvious fix. symtab_insert() keys on the permission name, so two
differently-named permissions may carry one value: nel still equals nprim,
the count agrees, and one slot is written twice while another is never
written at all. What holds for a well-formed policy is that the values
present are exactly {1..nprim} -- onto and injective -- so that is what 2/4
enforces.

3/4 and 4/4 fix the same defect at different layers, deliberately. A sparse
class value is tolerated: policydb_class_isvalid() and its siblings exist to
absorb it, so rejecting one at load would undo that, and only
security_get_classes() is at fault -- it builds its own array straight from
the hash table and never picked up a predicate. Booleans have no predicate,
and no consumer that could use one: cond_evaluate_expr(),
security_get_bools(), security_get_bool_value() and security_set_bools() all
walk bool_val_to_struct[] by index and dereference every entry. Density is
already an unstated requirement of that array, so 4/4 states it once, where
the array is built, rather than adding four guards.

A/B on a KASAN build of v7.2-rc1. Arms A, B and C carry the two merged
patches, so each reproduces on top of what is already applied; D ran on the
stock build, since the merged patches are in perm_read() and class_read()
and the boolean path does not go near them. Every policy is the stock
refpolicy image (135 classes, 324 booleans) with one u32 changed, written to
/sys/fs/selinux/load in a single write:

  A -- "process" permissions.nprim 31 -> 39, leaving slots 31..38 unwritten:
    without the series, NULL dereference; with it, -EINVAL at parse.
  B -- "process" permission "getrlimit" value 31 -> 1, colliding with
    "fork". nel and nprim both stay 31, so a count check accepts it. Same
    dereference; with the series, -EINVAL.
  C -- p_classes.nprim 135 -> 139: the class array rather than a permission
    array. With the series, security_get_classes() fails the lookup.
  D -- p_bools.nprim 324 -> 328: with the series, rejected at load with
    "boolean 325 is declared but not defined".
  Control: a well-formed policy loads on the patched kernel exactly as it
    does without the series. With timestamps stripped the two control arms
    are 33 lines each and the diff between them is empty.

A, B and C give:

  BUG: kernel NULL pointer dereference, address: 0000000000000000
  RIP: 0010:hashlen_string+0xa/0xc0
  Call Trace:
   d_alloc_name+0x61/0xa0
   sel_make_policy_nodes+0xb35/0x1310   <- A and B, via sel_make_perm_files
   sel_make_policy_nodes+0x8d5/0x1310   <- C, via sel_make_classes
   sel_write_load+0x2a5/0x490

and D faults earlier in the same function, on the array itself rather than
on a name derived from it:

  KASAN: null-ptr-deref in range [0x0000000000000000-0x0000000000000007]
  RIP: 0010:security_get_bools+0x287/0x790
  Call Trace:
   sel_make_policy_nodes+0x42f/0x1310   <- via sel_make_bools
   sel_write_load+0x2a5/0x490

Three distinct call sites in sel_make_policy_nodes(), which is what makes
these separate holes rather than one reached three times. D is first in that
function, so it is the one a sparse policy hits soonest.

1/4 came out of that A/B rather than from reading. The first build carrying
3/4 turned arm C into a general protection fault instead of a clean
rejection:

  RIP: 0010:selinux_policy_cancel+0x40/0x180
  Call Trace: sel_write_load+0x3c0/0x490 -> vfs_write -> ksys_write

sel_write_load() cancels the load when sel_make_policy_nodes() fails, and
the cancel dereferences the outgoing policy. On a first load there is none,
and sidtab is the first member of struct selinux_policy, hence the read at
offset 0. selinux_policy_commit(), which does the same
rcu_dereference_protected() a few lines away, guards with if (oldpolicy);
the cancel does not. It is reachable today through any -ENOMEM inside
sel_make_policy_nodes(); 3/4 would have made it policy-controlled, so it
goes first.

Two limits. The double-kstrdup leak 2/4 also closes is stated from the code,
not measured -- this rig has no CONFIG_DEBUG_KMEMLEAK, and the same crafted
policy oopses, which is the stronger oracle. And "conforming policies are
unaffected" rests on the patched control arm plus four classes checked by
hand, one of which is "capability": it has nprim == SEL_VEC_MAX exactly,
which is why the new rejection in 2/4 is a strict > rather than >=.

Based on selinux/stable-7.2 (9a82dcd98b6e), since 2/4 touches the functions
the merged series changed. Crafters and full logs on request.

[1] https://lore.kernel.org/selinux/CAHC9VhRt96xoRi9EcmU9cvBUiCJfrG=FBZPz92JyKmvQvesgvQ@mail.gmail.com/

---
Bryam Vargas (4):
      selinux: do not cancel a policy conversion that never started
      selinux: require a class's permission values to cover its permission count
      selinux: reject an unclaimed class value in security_get_classes()
      selinux: require every boolean value to be defined

 security/selinux/ss/policydb.c | 70 +++++++++++++++++++++++++++++++++++++++---
 security/selinux/ss/services.c | 28 +++++++++++++----
 2 files changed, 87 insertions(+), 11 deletions(-)
---
base-commit: 9a82dcd98b6e6e11cfd162410967951f12152528
change-id: 20260731-b4-disp-d32e997b-c002ecb15405

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

