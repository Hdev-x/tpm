package com.tj.app.common.pager;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 게시판 페이지네이션(페이저) 계산 클래스.
 *
 * Controller에서 이 객체를 생성하고 makePageNum() → makeStartNum() 순서로 호출하면
 * JSP에서 페이지 번호, 이전/다음 블럭 버튼, SQL OFFSET 값을 모두 사용할 수 있다.
 *
 * [페이지 구조 예시] 총 43개 글, 페이지당 10개, 블럭당 5개일 때:
 *   totalPage = 5 (ceil(43/10))
 *   1블럭: [1][2][3][4][5]
 *   현재 페이지 3 → curBlock=1, start=1, end=5
 * ============================================================ */
@Setter
@Getter
@ToString
public class Pager {

    private String search = ""; // 검색어 (기본값 빈 문자열)
    private String kind;        // 검색 컬럼 (v1:제목, v2:내용, v3:작성자)
    private Long page;          // 현재 페이지 번호 (1부터 시작)
    private Long perPage;       // 페이지당 글 수 (기본 10)
    private Long startNum;      // SQL OFFSET 값 → MyBatis 쿼리의 LIMIT #{startNum}, #{perPage}에 사용
    private boolean pre = true; // 이전 블럭 존재 여부 (true = 존재)
    private boolean next = true;// 다음 블럭 존재 여부 (true = 존재)
    private Long start;         // 현재 블럭의 첫 번째 페이지 번호
    private Long end;           // 현재 블럭의 마지막 페이지 번호

    // [주의] 필드로 선언해야 Lombok @Getter가 getTotalPage()를 생성하고
    // JSP에서 ${pager.totalPage}로 접근할 수 있다. 지역변수로 선언하면 JSP에서 못 읽는다.
    private Long totalPage;

    /** ============================================================
     * 현재 페이지 번호 반환. null 또는 0 이하이면 1로 보정한다.
     * ============================================================ */
    public Long getPage() {
        if (page == null || page < 1) {
            this.page = 1L;
        }
        return this.page;
    }

    /** ============================================================
     * 페이지당 글 수 반환. null 또는 0 이하이면 10으로 보정한다.
     * ============================================================ */
    public Long getPerPage() {
        if (perPage == null || perPage < 1) {
            this.perPage = 10L;
        }
        return this.perPage;
    }

    /** ============================================================
     * 전체 글 수를 받아 페이지 번호 관련 값을 모두 계산한다.
     *
     * [실행 흐름]
     * 1. totalPage = ceil(전체글수 / 페이지당글수)
     * 2. totalBlock = ceil(totalPage / 블럭당페이지수)
     * 3. curBlock = 현재 페이지가 속한 블럭 번호
     * 4. start/end = 현재 블럭의 첫/끝 페이지 번호
     * 5. 마지막 블럭이면 end = totalPage, next = false
     * 6. 첫 번째 블럭이면 pre = false
     *
     * @param totalCount DB에서 조회한 전체 글 수
     * ============================================================ */
    public void makePageNum(Long totalCount) {
        this.totalPage = (long) (Math.ceil((double) totalCount / this.getPerPage()));

        Long perBlock = 5L; // 한 블럭에 표시할 페이지 번호 개수
        Long totalBlock = this.totalPage / perBlock;
        if (this.totalPage % 5 != 0) totalBlock++;

        // [실행 흐름] 현재 페이지 번호로 현재 블럭 번호 계산
        Long curBlock = this.getPage() / perBlock;
        if (this.page % perBlock != 0) curBlock++;

        start = (curBlock - 1) * perBlock + 1; // 현재 블럭 시작 페이지
        end = curBlock * perBlock;              // 현재 블럭 끝 페이지

        if (curBlock == totalBlock) {
            end = this.totalPage; // [실행 흐름] 마지막 블럭은 totalPage로 끝을 제한
            next = false;
        }
        if (curBlock < 2) {
            pre = false; // [실행 흐름] 첫 번째 블럭은 이전 버튼 비활성화
        }
    }

    /** ============================================================
     * SQL OFFSET 값(startNum)을 계산한다.
     * startNum = (현재페이지 - 1) × 페이지당글수
     * 예) 3페이지, 10개씩 → startNum = 20 → LIMIT 20, 10
     * ============================================================ */
    public void makeStartNum() {
        this.startNum = (this.getPage() - 1) * this.getPerPage();
    }
}