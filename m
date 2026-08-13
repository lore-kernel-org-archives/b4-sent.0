From: Bingfang Guo <bingfangguo@tencent.com>
Subject: [PATCH RFC 0/5] memcg: fix dying memcg pinned by swapped out shmem
 pages
Date: Thu, 13 Aug 2026 16:52:01 +0800
Message-Id: <20260813-memcgid-objcg-v1-0-83d21c685b77@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALGFfWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0Mj3dzU3OT0zBTd/KSs5HTdlFTLNFNzi9Q0QyMLJaCegqLUtMwKsHn
 RSkFuzkqxtbUAC7c3uGQAAAA=
To: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Dave Chinner <david@fromorbit.com>, Qi Zheng <qi.zheng@linux.dev>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>
Cc: cgroups@vger.kernel.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Bingfang Guo <bfguo@icloud.com>, 
 Bingfang Guo <bingfangguo@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786611130; l=8802;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=KF0xDds5w/g3aR4DwwjXLrfgHcalIYAD5qSFXpEkNZo=;
 b=hUrUDZC9vcOK4OhNBfILovwU//i4z7hYvRM++jGf52u9aDMx/T9svF5e/5e6H0/Vo6vuGcDvg
 617UoZDI/mGCGlGwEbZl9RhW3tXxl9pF2W2iefCg3lfi/SV4y/rTPQ6
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the private ID of a memory cgroup holds a reference to its
css, so that users such as list_lru and swap entries can look the memcg
up by ID even after it has gone offline.

This has a downside: a memcg that still owns swapped out shmem pages is
pinned via its private ID and is never released until those pages are
swapped back in. Workloads that create and destroy many cgroups can
accumulate a large number of dying memcgs.

This series fixes that by moving the memcg private ID reference count
from the memcg to its object cgroup. The objcg is cheap to keep alive
and is reparented to an online ancestor when its memcg goes offline, so
holding the ID no longer pins the css.

Patch 1 (memcg: move memcg private ID refcount to objcg)

Move the ID refcount from the memcg to its objcg, so swapped out pages
no longer pin the dying memcg. The online state pins the objcg, and the
ID is released in css_released() after reparenting; this guarantees the
id refcount is alive for any caller holding a memcg reference. After
reparenting, mem_cgroup_from_private_id() returns a live ancestor
instead of the original memcg; callers that need the exact memcg are
fixed in patch 5.

Patch 2 (memcg: get stable memcg first before getting memcgid reference)

Both __memcg1_swapout() and __mem_cgroup_try_charge_swap() now take a
stable memcg reference first via get_mem_cgroup_from_objcg() and pin
the ID afterwards, dropping the rcu_read_lock() usage and the
get-error-put handling, and recording exactly the memcg the folio
belongs to in the swap entry.

Patch 3 (memcg: remove retry logic in mem_cgroup_private_id_get_online)

With the ID released only in css_released() (patch 1) and every caller
holding a stable reference (patch 2), the retry loop that walked up the
parent chain can never trigger. Remove it, rename the function to
mem_cgroup_private_id_get().

Patch 4 (memcg: add a helper to get online memcg from memcgid)

Add mem_cgroup_from_private_id_online(), which looks the ID up and
takes a reference through the objcg. Since the objcg is always
reparented to an online memcg, this guarantees an online memcg. Use it
in mem_cgroup_swapin_charge_folio(), dropping the manual id lookup and
css_tryget_online() check under the RCU read lock.

Patch 5 (memcg: filter out reparented memcgs got using memcgid)

After reparenting, mem_cgroup_from_private_id() can return a memcg that
no longer owns the ID. Callers such as list_lru and workingset refault
expect exactly the memcg the ID refers to, so check that the returned
memcg still owns the ID and return NULL otherwise, letting the callers
skip the entry.

The following program reproduces the problem: it repeatedly creates a
memcg, dirties one shared shmem page, pushes it to swap, and destroys
the cgroup. Each iteration leaves a dying memcg pinned by the swapped
out page.

shmem_dying_memcg.c:

```c

static int write_str(const char *path, const char *val) {
    int fd = open(path, O_WRONLY);
    if (fd < 0) return -1;
    int rc = write(fd, val, strlen(val)) < 0 ? -1 : 0;
    close(fd);
    return rc;
}

static long long dying_memcgs(void) {
    FILE *f = fopen(CG_ROOT "/cgroup.stat", "r");
    if (!f) return -1;
    char k[64];
    long long v = -1;
    while (fscanf(f, "%63s %lld", k, &v) == 2)
        if (!strcmp(k, "nr_dying_subsys_memory")) break;
    fclose(f);
    return v;
}

// worker: join the memcg, dirty one shared shmem page, swap it out, exit.
static void worker(const char *cgdir, const char *shmfile) {
    char pid[16];
    snprintf(pid, sizeof pid, "%d", getpid());
    if (write_str(cgdir, pid) < 0) _exit(1);           // cgroup.procs

    int fd = open(shmfile, O_CREAT | O_RDWR | O_TRUNC, 0644);
    if (fd < 0 || ftruncate(fd, PAGE) < 0) _exit(2);
    char *p = mmap(NULL, PAGE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (p == MAP_FAILED) _exit(3);
    close(fd);

    p[0] = 1;                                          // fault in + dirty
    if (madvise(p, PAGE, MADV_PAGEOUT) < 0) _exit(4);  // push to swap
    _exit(0);
}

static void one_iter(long i) {
    char cgdir[256], procs[300], shmfile[300];
    snprintf(cgdir,   sizeof cgdir,   "%s/m%ld", CG_BASE, i);
    snprintf(procs,   sizeof procs,   "%s/cgroup.procs", cgdir);
    snprintf(shmfile, sizeof shmfile, "%s/f%ld", SHM_DIR, i);

    if (mkdir(cgdir, 0755) < 0 && errno != EEXIST) return;

    pid_t pid = fork();
    if (pid == 0) worker(procs, shmfile);
    waitpid(pid, NULL, 0);

    rmdir(cgdir);   // memcg goes dying; swapped page pins its id
}

static void cleanup(void) {
    struct dirent *de;
    char p[512];
    DIR *d = opendir(CG_BASE);
    if (d) {
        while ((de = readdir(d)))
            if (de->d_name[0] == 'm') {
                snprintf(p, sizeof p, "%s/%s", CG_BASE, de->d_name);
                rmdir(p);
            }
        closedir(d);
    }
    d = opendir(SHM_DIR);
    if (d) {
        while ((de = readdir(d)))
            if (de->d_name[0] != '.') {
                snprintf(p, sizeof p, "%s/%s", SHM_DIR, de->d_name);
                unlink(p);
            }
        closedir(d);
    }
    rmdir(CG_BASE);
    rmdir(SHM_DIR);
    printf("cleanup done; nr_dying_subsys_memory = %lld\n", dying_memcgs());
}

int main(int argc, char **argv) {
    if (geteuid() != 0) { fprintf(stderr, "run as root\n"); return 1; }

    if (argc > 1 && !strcmp(argv[1], "--cleanup")) { cleanup(); return 0; }
    long n = argc > 1 ? atol(argv[1]) : 1000;

    mkdir(CG_BASE, 0755);
    write_str(CG_ROOT "/cgroup.subtree_control", "+memory");
    if (write_str(CG_BASE "/cgroup.subtree_control", "+memory") < 0) {
        fprintf(stderr, "enable +memory: %s\n", strerror(errno));
        return 1;
    }
    mkdir(SHM_DIR, 0755);

    printf("before: nr_dying_subsys_memory = %lld\n", dying_memcgs());
    for (long i = 0; i < n; i++) one_iter(i);
    printf("after:  nr_dying_subsys_memory = %lld  (created %ld memcgs)\n",
           dying_memcgs(), n);
    printf("release with: sudo %s --cleanup\n", argv[0]);
    return 0;
}
```

Run with:

```bash
echo "=== before ==="
grep dying /sys/fs/cgroup/cgroup.stat

sudo ./shmem_dying_memcg "$@"

sleep 1

echo
echo "=== after (root cgroup.stat) ==="
grep dying /sys/fs/cgroup/cgroup.stat
```

To release the pinned memcgs:
$ sudo ./shmem_dying_memcg --cleanup

Results on my machine (20000 iterations):

Before this series, all 20000 destroyed memcgs stay dying:
```
=== before ===
nr_dying_descendants 20002
nr_dying_subsys_cpuset 0
nr_dying_subsys_cpu 0
nr_dying_subsys_io 2
nr_dying_subsys_memory 20002
nr_dying_subsys_perf_event 0
nr_dying_subsys_hugetlb 0
nr_dying_subsys_pids 0
before: nr_dying_subsys_memory = 20002
after:  nr_dying_subsys_memory = 20002  (created 20000 memcgs)
release with: sudo ./shmem_dying_memcg --cleanup

=== after (root cgroup.stat) ===
nr_dying_descendants 20002
nr_dying_subsys_cpuset 0
nr_dying_subsys_cpu 0
nr_dying_subsys_io 2
nr_dying_subsys_memory 20002
nr_dying_subsys_perf_event 0
nr_dying_subsys_hugetlb 0
nr_dying_subsys_pids 0
```

After this series, dying memcgs no longer accumulate:
```
=== before ===
nr_dying_descendants 0
nr_dying_subsys_cpuset 0
nr_dying_subsys_cpu 0
nr_dying_subsys_io 0
nr_dying_subsys_memory 0
nr_dying_subsys_perf_event 0
nr_dying_subsys_hugetlb 0
nr_dying_subsys_pids 0
before: nr_dying_subsys_memory = 0
after:  nr_dying_subsys_memory = 314  (created 20000 memcgs)
release with: sudo ./shmem_dying_memcg --cleanup

=== after (root cgroup.stat) ===
nr_dying_descendants 0
nr_dying_subsys_cpuset 0
nr_dying_subsys_cpu 0
nr_dying_subsys_io 0
nr_dying_subsys_memory 0
nr_dying_subsys_perf_event 0
nr_dying_subsys_hugetlb 0
nr_dying_subsys_pids 0
```

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
Bingfang Guo (5):
      memcg: move memcg private ID refcount to objcg
      memcg: get stable memcg first before getting memcgid reference
      memcg: remove retry logic in mem_cgroup_private_id_get_online
      memcg: add a helper to get online memcg from memcgid
      memcg: filter out reparented memcgs got using memcgid

 include/linux/memcontrol.h |  11 +++-
 mm/list_lru.c              |   2 +-
 mm/memcontrol-v1.c         |  23 +++----
 mm/memcontrol-v1.h         |   3 +-
 mm/memcontrol.c            | 151 ++++++++++++++++++++++++++++++---------------
 mm/workingset.c            |   6 +-
 6 files changed, 126 insertions(+), 70 deletions(-)
---
base-commit: 288058d8db5d35623228d84f48d9bea3707d5c85
change-id: 20260812-memcgid-objcg-de9f578ef128

Best regards,
-- 
Bingfang Guo <bingfangguo@tencent.com>

