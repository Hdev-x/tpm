package com.tj.app.market.coin;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CoinCommentLikeDTO {
    private Long likeNo;
    private Long commentNo;
    private String username;
}
