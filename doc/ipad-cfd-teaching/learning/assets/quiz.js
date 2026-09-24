/* ============================================================
   quiz.js —— 即时反馈练习组件（所有 lessons 共用）

   用法：页面里放一个 id="quiz" 的容器，每道题写成：
     <div class="q" data-answer="正确选项的下标（从 0 数）">
       <p class="stem">题干</p>
       <div class="opts"><button class="opt" type="button" aria-pressed="false">选项</button>…</div>
       <p class="fb" hidden data-fb="解释（可含 HTML）"></p>
     </div>
   然后在页尾用一个 script 标签引用本文件（相对路径 ../assets/quiz.js）。
   注意：本文件会被内联进发布页，所以这里的注释里不能出现闭合的 script 标签字面量。

   规则：每题只能答一次；答完立刻标出正确选项并显示解释。
   ============================================================ */
(function () {
  var root = document.getElementById("quiz");
  if (!root) return;
  root.querySelectorAll(".q").forEach(function (q) {
    var answer = parseInt(q.getAttribute("data-answer"), 10);
    var opts = Array.prototype.slice.call(q.querySelectorAll(".opt"));
    var fb = q.querySelector(".fb");
    opts.forEach(function (btn, i) {
      btn.addEventListener("click", function () {
        if (btn.disabled) return;
        var correct = (i === answer);
        btn.setAttribute("aria-pressed", "true");
        btn.classList.add(correct ? "right" : "wrong");
        opts.forEach(function (b, j) {
          b.disabled = true;
          if (j === answer) b.classList.add("right");
        });
        fb.classList.add(correct ? "right" : "wrong");
        fb.innerHTML = (correct ? "<strong>对了。</strong> " : "<strong>不对。</strong> ") + fb.getAttribute("data-fb");
        fb.hidden = false;
      });
    });
  });
})();
