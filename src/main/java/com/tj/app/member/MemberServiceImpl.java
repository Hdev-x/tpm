package com.tj.app.member;

import com.tj.app.market.coin.order.CoinMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.validation.BindingResult;

@Service
public class MemberServiceImpl implements MemberService {

    @Autowired
    private MemberMapper memberMapper;

    @Autowired
    private CoinMapper coinMapper;
    
    @Override
    public boolean doubleCheck(MemberDTO memberDTO, BindingResult bindingResult) throws Exception{
		// false : 검증 통과
		// true : 검증 실패
		boolean result = false;
		
		result = bindingResult.hasErrors();
		
		// password 일치 검증
		if(!memberDTO.getPassword().equals(memberDTO.getPassword())) {
			bindingResult.rejectValue("passwordCheck", "member.passwordCheck.notEqual");
			result = true;
		}
		
		// ID 중복 검사
		MemberDTO m = memberMapper.login(memberDTO);
		if(m != null) {
			result = true;
			bindingResult.rejectValue("username", "member.idCheck.equal");
		}
		
		return result;
	}

    @Override
    public int create(MemberDTO memberDTO) throws Exception {
        int result = memberMapper.create(memberDTO);
        if (result > 0) {
            coinMapper.createWallet(memberDTO.getUsername());
        }
        return result;
    }

    @Override
    public MemberDTO read(MemberDTO memberDTO) throws Exception {
        // 이제 권한 정보까지 조인해서 가져오는 mapper의 login을 호출합니다.
        return memberMapper.login(memberDTO); 
    }

    @Override
    public int update(MemberDTO memberDTO) throws Exception {
        return memberMapper.update(memberDTO);
    }

    @Override
    public int delete(MemberDTO memberDTO) throws Exception {
        return memberMapper.delete(memberDTO);
    }
}