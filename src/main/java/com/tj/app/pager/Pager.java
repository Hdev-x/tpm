package com.tj.app.pager;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Setter
@Getter
@ToString
public class Pager {

		// 검색어
		private String search = "";

		// 검색컬럼
		private String kind; // v1:title, v2:contents, v3:writer

		// 페이지 번호
		private Long page;

		// 페이지당 보여줄 글의 갯수
		private Long perPage;

		// offset 번호
		private Long startNum;

		// 이전블럭 유무
		private boolean pre = true;// true 이전블럭이 존재

		// 다음블럭 유무
		private boolean next = true;// true 다음 블럭이 존재

		private Long start;

		private Long end;

		public Long getPage() {
			if (page == null || page < 1) {
				this.page = 1L;
			}
			return this.page;
		}

		public Long getPerPage() {
			if (perPage == null || perPage < 1) {
				this.perPage = 10L;
			}
			return this.perPage;
		}

		public void makePageNum(Long totalCount) {
			// 1. 총 페이지 수 구하기
			Long totalPage = (long) (Math.ceil((double) totalCount / this.getPerPage()));

			// 2. 총 블럭 수 구하기
			Long perBlock = 5L;// 한블럭당 출력한 번호의 갯수

			Long totalBlock = totalPage / perBlock;
			if (totalPage % 5 != 0) {
				totalBlock++;
			}

			// 3. 페이지 번호로 현재 블럭 번호 구하기
			Long curBlock = this.getPage() / perBlock;
			if (this.page % perBlock != 0) {
				curBlock++;
			}

			// 4. 현재블럭번호로 시작번호와 끝번호 구하기
			start = (curBlock - 1) * perBlock + 1;
			end = curBlock * perBlock;

			// 5. 현재블럭번호가 총블럭과 같다면
			if (curBlock == totalBlock) {
				end = totalPage;
				next = false;
			}

			// 6. 블럭 유무
			if (curBlock < 2) {
				pre = false;
			}

		}

		public void makeStartNum() {
			// 1, 0: 2, 5
			this.startNum = (this.getPage() - 1) * this.getPerPage();
		}
	}