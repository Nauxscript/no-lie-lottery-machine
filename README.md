# 实诚的抽奖机器

## 描述

创建一个抽奖规则，抽奖规则中定义了这个抽奖的奖品以及每个奖品中奖的概率。

比如，现在创建一种抽奖有如下几个奖品，以及其对应中奖概率：

1. `手机`：`0.1`
2. `电脑`：`0.05`
3. `键盘`：`0.2`
4. `鼠标`：`0.3`
5. `很遗憾，你没有中奖`：`0.35`

然后根据这个规则，就进行奖品的抽取，抽取结果，会保存在链上，后续可以查询。

## 功能

### 1. 创建规则

#### `Rule` 规则的接口：

- `ruleId` 规则 ID
- `owner` 创建者
- `lotteryProbabilities` 中奖奖品及其概率的映射
- `createTime` 创建时间
- `avaible` 是否可用

```solidity
// 规则 ID 生成方法? 好像不需要了，废弃。
function generateRuleId() public pure returns (bytes32) {
  // 根据 创建者和当前时间 创建一个规则 id
  // seed 是合约的私有状态变量, 每次创建新的规则 ID, 都自增
  bytes memory data = abi.encodePacked(msg.sender, block.timestamp, seed);
  bytes32 hash = keccak256(data);
  seed++;
  return hash;
} 

```

#### `ruleset` 规则集:

从规则 ID 映射规则本身

```
{
  ruleId: rule
}
```

#### `owner2rules` 创建者与规则映射

从创建者地址映射到规则:

{
  owner: [...ruleIds] // 一个用户可能拥有多个规则
}

#### 效果：

返回创建好的 rule 的 ID;


~~### 2. 删除规则~~

~~### 3. 修改规则~~

### 4. 进行抽奖

#### `Result` 的接口 

- `resultId` 抽奖结果 ID
- `ruleId` 使用了的规则 ID
- `owner` 创建者
- `createTime` 创建时间
- `reward` 奖品 -- 文本

#### 入参：规则 ID

#### 返回：抽奖 ID

由于 Chainlink 的随机数接口是异步的，无法在调用后立刻返回结果，而是在 Chainlink 预言机生成有效随机数后，调用合约中实现的 `fulfillRandomWords` 方法，此时合约在次方法内才可以获取到生成的随机数；在请求了 Chainlink VRF 后，其会立刻返回一个 RequestId；则记录这个 RequestId 并于当前抽奖的用户、使用的抽奖规则等做一个映射；在后续 `fulfillRandomWords` 被调用时再使用随机数进行抽奖，生成最终的获奖奖品。

### 5. 查询所有中奖情况

#### `user2results` 抽奖结果映射

从抽奖者地址映射到结果:

#### 入参：无

#### 返回 `msg.sender` 所有的中奖情况

### 6. 查询在指定规则下的中奖情况

#### 入参：规则 ID

#### 返回对应中奖情况

### 7. 查询当前用户创建的规则

#### 入参：无