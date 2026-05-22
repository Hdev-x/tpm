/* =====================================================
   coin-common.js - 코인 댓글 UI에서 함께 쓰는 공통 함수
   chart-toss-coin.js와 coinList.js가 이 파일의 함수를 호출한다.
   ===================================================== */

/* =====================================================
   [이 파일을 읽는 법]

   1. 역할
      코인 댓글 데이터를 화면에 그리는 공통 함수 모음.
      chart-toss-coin.js와 coinList.js에서 함께 사용한다.

   2. 중심 함수
      cmAppendChatMsg()
      - 댓글 데이터 하나를 댓글 카드 HTML로 바꾼다.
      - 마지막에 #chat-messages 영역에 붙인다.

   3. 전체 흐름
      댓글 데이터 받기
      -> 화면에 넣기 전 값 정리
      -> 댓글 카드 HTML 조립
      -> 더 보기/좋아요에 필요한 data-* 값 저장
      -> 댓글 목록에 삽입

   4. 보조 함수
      cmAvatarColor()              이름으로 아바타 색 결정
      cmRelTime()                  작성 시각을 상대 시간으로 변환
      cmToggleMore()/Less()        긴 댓글 더 보기/접기

   5. 주의해서 볼 값
      safe()                       사용자 입력을 HTML에 넣기 전 치환
      data-full                    접힌 댓글의 전체 원문 보관
      data-comment-no              좋아요 이벤트용 댓글 번호
      scroll                       댓글 삽입 위치 결정
   ===================================================== */

/**
 * 사용자 이름을 기준으로 아바타 배경색을 고른다.
 *
 * @param {string} name 색을 정할 기준이 되는 사용자 이름
 * @return {string} CSS에서 바로 쓸 수 있는 HEX 색상 문자열
 */
function cmAvatarColor(name) {
    const palette = ['#4caf50','#2196f3','#e91e63','#ff9800','#9c27b0','#00bcd4','#f44336','#3f51b5','#009688','#795548'];

    // [코드 읽기] h는 이름 전체를 숫자 하나로 압축해 가는 누적값이다.
    let h = 0;

    // [실행 흐름] 각 글자의 문자 코드를 h에 섞어 넣어서 같은 이름은 항상 같은 숫자가 나오게 한다.
    for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) & 0x7fffffff;

    // [코드 읽기] 나머지 연산(%)으로 팔레트 범위 안의 인덱스를 만들고 그 색을 반환한다.
    return palette[h % palette.length];
}

/**
 * 작성 시각을 댓글 UI에 표시할 짧은 상대 시간으로 바꾼다.
 *
 * @param {string} createdAt 서버에서 받은 작성 시각 문자열
 * @return {string} 예: 방금, 3분, 2시간, 1일
 */
function cmRelTime(createdAt) {
    // [주의] 작성 시각이 없으면 화면에 이상한 날짜가 나오지 않도록 빈 문자열로 끝낸다.
    if (!createdAt) return '';

    // [코드 읽기] 현재 시각과 작성 시각의 차이를 밀리초로 구한 뒤 분 단위로 바꾼다.
    const diff = Date.now() - new Date(createdAt).getTime();
    const m = Math.floor(diff / 60000);

    // [실행 흐름] 분 -> 시간 -> 일 순서로 범위를 넓혀 가며 표시 문자열을 결정한다.
    if (m < 1)  return '방금';
    if (m < 60) return m + '분';
    const h = Math.floor(m / 60);
    if (h < 24) return h + '시간';
    return Math.floor(h / 24) + '일';
}

/**
 * 접힌 댓글에서 '더 보기'를 눌렀을 때 원문 전체를 보여준다.
 *
 * @param {HTMLElement} btn 사용자가 클릭한 '더 보기' 버튼
 */
function cmToggleMore(btn) {
    // [DOM 연결] 버튼은 .cm-text 안에 있으므로 parentElement가 댓글 본문 영역이다.
    const textEl = btn.parentElement;
    const full = textEl.dataset.full;

    // [실행 흐름] cmAppendChatMsg가 data-full에 저장해 둔 원문으로 본문을 교체하고 '접기' 버튼을 붙인다.
    textEl.innerHTML = full + ' <button class="cm-more-btn" onclick="cmToggleLess(this)">접기</button>';
}

/**
 * 펼쳐진 댓글에서 '접기'를 눌렀을 때 다시 100자 미리보기로 줄인다.
 *
 * @param {HTMLElement} btn 사용자가 클릭한 '접기' 버튼
 */
function cmToggleLess(btn) {
    // [DOM 연결] 펼칠 때와 같은 .cm-text 요소에서 원문을 다시 꺼낸다.
    const textEl = btn.parentElement;
    const full = textEl.dataset.full;
    const MAX = 100;

    // [코드 읽기] slice(0, MAX)는 0번째 글자부터 MAX 직전까지 잘라 미리보기 문자열을 만든다.
    const preview = full.slice(0, MAX) + '...';

    // [실행 흐름] 미리보기 텍스트로 되돌리고 다시 펼칠 수 있도록 '더 보기' 버튼을 붙인다.
    textEl.innerHTML = preview + ' <button class="cm-more-btn" onclick="cmToggleMore(this)">더 보기</button>';
}

/**
 * 댓글 데이터 하나를 화면에 표시할 DOM 카드로 만들어 #chat-messages에 추가한다.
 *
 * @param {string} username 작성자 이름
 * @param {string} content 댓글 본문
 * @param {string} createdAt 작성 시각
 * @param {boolean} scroll true면 위에 추가하고 false면 아래에 추가한다
 * @param {string|null} imageUrl 첨부 이미지 주소
 * @param {string|null} profileFileName 프로필 이미지 파일명
 * @param {number|null} commentNo 좋아요 API에 사용할 댓글 번호
 * @param {number} likeCount 좋아요 수
 * @param {boolean} likedByMe 현재 사용자가 좋아요를 눌렀는지 여부
 */
function cmAppendChatMsg(username, content, createdAt, scroll = true, imageUrl = null, profileFileName = null, commentNo = null, likeCount = 0, likedByMe = false) {

    // [DOM 연결] list.jsp와 chart.jsp의 댓글 목록 영역은 같은 id인 #chat-messages를 사용한다.
    const msgs = document.getElementById('chat-messages');
    if (!msgs) return;

    // [실행 흐름] 첫 댓글이 들어오면 "댓글 없음" 안내 요소를 제거하고 실제 댓글 목록으로 바꾼다.
    const empty = msgs.querySelector('.chat-empty');
    if (empty) empty.remove();

    // [주의] 댓글 내용과 사용자 이름은 innerHTML에 들어가므로 < 문자를 HTML 태그로 해석되지 않게 바꾼다.
    const safe    = s => s.replace(/</g, '&lt;');

    // [실행 흐름] 댓글 카드의 왼쪽 영역에 들어갈 아바타 표시값을 준비한다.
    const color   = cmAvatarColor(username);
    const initial = username.charAt(0).toUpperCase();
    const avatarHtml = profileFileName
        ? '<img src="/files/profile/' + profileFileName + '" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">'
        : initial;
    const time = cmRelTime(createdAt);

    // [실행 흐름] 본문이 길면 화면에는 100자만 보여 주고 원문은 data-full에 보관한다.
    const MAX     = 100;
    const isTrunc = content.length > MAX;
    const preview = isTrunc ? safe(content.slice(0, MAX)) + '...' : safe(content);
    const full    = safe(content);

    // [코드 읽기] 이미지가 있는 댓글만 img 태그를 만들고, 클릭하면 cmOpenImage(this)가 원본 보기 팝업을 연다.
    const imgHtml = imageUrl
        ? '<img class="cm-image" src="' + imageUrl + '" alt="" onclick="cmOpenImage(this)">'
        : '';

    // [실행 흐름] 좋아요 여부에 따라 하트 SVG의 색과 버튼 class를 다르게 만든다.
    const heartFill   = likedByMe ? '#e91e63' : 'none';
    const heartStroke = likedByMe ? '#e91e63' : 'currentColor';

    // [DOM 연결] data-comment-no는 나중에 좋아요 클릭 이벤트가 어떤 댓글인지 찾을 때 쓰는 값이다.
    const likeHtml = commentNo
        ? '<div class="cm-actions"><button class="cm-like-btn' + (likedByMe ? ' liked' : '') + '" data-comment-no="' + commentNo + '">' +
              '<svg viewBox="0 0 24 24" fill="' + heartFill + '" stroke="' + heartStroke + '" stroke-width="1.8" width="16" height="16"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>' +
              '<span class="cm-like-count">' + (likeCount || 0) + '</span>' +
          '</button></div>'
        : '';

    // [실행 흐름] 여기서부터 댓글 카드 HTML을 한 번에 조립한다.
    // [DOM 연결] cm-left는 아바타/등급, cm-right는 작성자/시간/본문/이미지/좋아요 영역이다.
    // [DOM 연결] data-full은 더 보기/접기 함수가 다시 읽을 원문이고, data-trunc는 현재 축약 여부를 담는다.
    const div = document.createElement('div');
    div.className = 'chat-msg';
    div.innerHTML =
        '<div class="cm-left">' +
            '<div class="cm-avatar" style="background:' + (profileFileName ? 'transparent' : color) + '">' + avatarHtml + '</div>' +
            '<span class="cm-rank">주주</span>' +
        '</div>' +
        '<div class="cm-right">' +
            '<div class="cm-meta">' +
                '<span class="cm-name">' + safe(username) + '</span>' +
                '<span class="cm-time">' + time + '</span>' +
            '</div>' +
            '<div class="cm-text" data-full="' + full.replace(/"/g, '&quot;') + '" data-trunc="' + (isTrunc ? '1' : '0') + '">' +
                preview +
                (isTrunc ? ' <button class="cm-more-btn" onclick="cmToggleMore(this)">더 보기</button>' : '') +
            '</div>' +
            imgHtml +
            likeHtml +
        '</div>';

    // [실행 흐름] 실시간으로 도착한 댓글은 위에, 과거 기록을 불러온 댓글은 아래에 붙인다.
    if (scroll) msgs.prepend(div);
    else        msgs.appendChild(div);
}
