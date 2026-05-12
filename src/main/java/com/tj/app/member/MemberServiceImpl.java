package com.tj.app.member;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MemberServiceImpl implements MemberService {

    @Autowired
    private MemberMapper memberMapper;

    @Override
    public int create(MemberDTO memberDTO) throws Exception {
        return memberMapper.create(memberDTO);
    }

    @Override
    public MemberDTO read(MemberDTO memberDTO) throws Exception {
        return memberMapper.read(memberDTO);
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