package com.tj.app.market.community;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MarketCommentLikeDTO {
    private Long likeNo;
    private Long commentNo;
    private String username;
}
