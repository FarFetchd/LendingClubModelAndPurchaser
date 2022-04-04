#include <cstdlib>
#include <vector>
#include <Rcpp.h>

#include <cstdio>
#include <sys/inotify.h>
#include <unistd.h>

// Input: name (or path) of dir to watch.
// Returns the file that was moved in. (Just name, not path).

// [[Rcpp::export]]
Rcpp::String inotifyWaitForMoveIn(std::string input)
{
  int inotify_fd = inotify_init();
  if (inotify_fd < 0)
  {
    perror("inotify_init failed");
    exit(1);
  }

  // rather than IN_MOVED_TO could do IN_ALL_EVENTS
  int watch_descriptor =
      inotify_add_watch(inotify_fd, input.c_str(), IN_MOVED_TO);
  if (watch_descriptor < 0)
  {
    perror("inotify_add_watch failed!!\n");
    exit(1);
  }

  while (true)
  {
    char buf[4096];
    if (read(inotify_fd, buf, 4096) < 1)
    {
      perror("read");
      exit(1);
    }
    struct inotify_event* in_ev = (struct inotify_event*)buf;
    if ((in_ev->mask & IN_MOVED_TO) != 0)
    {
      inotify_rm_watch(inotify_fd, watch_descriptor);
      close(inotify_fd);
      return Rcpp::String(in_ev->name);
    }
  }
  return Rcpp::String();
}
